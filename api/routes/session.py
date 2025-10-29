import io
import asyncio
from fastapi import APIRouter, Request, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from datetime import datetime
import json
import logging
from api.routes.auth_utils import get_current_user
from api.core.cache import  cache_transcript , get_cached_transcript
from supabase import AsyncClient
from redis.asyncio import Redis

router = APIRouter(prefix="/session", tags=["session"])


# -----------------------
# GET TRANSCRIPT
# -----------------------
@router.get("/get_transcript")
async def get_transcript(
    request: Request,
    session_id: str,
    user=Depends(get_current_user)
):
    """
    Return the concatenated transcript text for a given session_id.
    First tries Redis cache.
    """
    redis_client: Redis = request.app.state.redis_client
    supabase: AsyncClient = request.app.state.supabase

    # Try Redis cache first
    cached_transcripts = await get_cached_transcripts(redis_client, user.id, session_id)
    if cached_transcripts:
        logging.info(f"Cache hit for session {session_id}")
        original_text = cached_transcripts.get("original_text", "")
        translated_text = cached_transcripts.get("translated_text", "")
        created_at = cached_transcripts.get("start_time", datetime.utcnow().isoformat())
    else:
        logging.info(f"Cache miss for session {session_id}, fetching from Supabase")
        response = await supabase.table("transcripts").select("*").eq("session_id", session_id).eq("chunk_index", -1).execute()
        if not response.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"No transcripts found for session {session_id}")
        original_text = response.data[0].get("original_text", "")
        translated_text = response.data[0].get("translated_text", "")
        created_at = response.data[0].get("created_at", datetime.utcnow().isoformat())
        # cache the result in Redis for future requests
        await cache_transcript(
            redis_client,
            user.id,
            response.data[0].get("id", ""),
            session_id,
            created_at,
            original_text,
            translated_text
        )

    return {
        "session_id": session_id,
        "user_id": user.id,
        "original_text": original_text.strip(),
        "translated_text": translated_text.strip(),
        "created_at": created_at
    }


# -----------------------
# GET LAST TRANSCRIPTS
# -----------------------
@router.get("/get_last_transcripts")
async def get_last_transcripts(
    request: Request,
    user=Depends(get_current_user),
    number_sessions: int = 10,
):
    """
    Return the last N session summaries for the authenticated user.
    """
    supabase: AsyncClient = request.app.state.supabase
    redis = request.app.state.redis_client

    # --------------------------
    # Step 1: Get last N session IDs from Redis
    # --------------------------
    recent_key = f"user:{user.id}:recent"
    session_ids = await redis.lrange(recent_key, 0, number_sessions - 1)
    session_ids = [sid.decode() if isinstance(sid, bytes) else sid for sid in session_ids]

    # Fetch cached transcripts for those sessions
    cached_sessions = []
    if session_ids:
        results = await asyncio.gather(
            *(redis.hget(f"user:{user.id}", f"session:{sid}") for sid in session_ids)
        )
        cached_sessions = [
            json.loads(r) for r in results if r
        ]

    # --------------------------
    # Step 2: Fallback to Supabase if not enough
    # --------------------------
    if len(cached_sessions) < number_sessions:
        cached_set = {s["transcript_id"] for s in cached_sessions}
        resp = await supabase.table("sessions").select("*") \
                    .eq("user_id", user.id) \
                    .order("started_at", desc=True) \
                    .limit(number_sessions * 2).execute()
        fresh_sessions = [
            s for s in (resp.data or []) 
            if s["id"] not in cached_set
        ]
        cached_sessions += fresh_sessions[:number_sessions - len(cached_sessions)]

    if not cached_sessions:
        return []

    # --------------------------
    # Step 3: Fetch final transcripts from Supabase if needed
    # --------------------------
    session_ids_final = [s["id"] for s in cached_sessions if "transcript_id" not in s]
    transcripts_resp = []
    if session_ids_final:
        transcripts_resp = await supabase.table("transcripts").select("*") \
                                .in_("session_id", session_ids_final) \
                                .eq("chunk_index", -1).execute()
        transcripts = transcripts_resp.data or []

        # Update cached_sessions with fetched transcripts
        for s in cached_sessions:
            if "transcript_id" not in s:
                for t in transcripts:
                    if t["session_id"] == s["id"]:
                        s.update(t)
                        break

    # --------------------------
    # Step 4: Format response
    # --------------------------
    aggregated_sessions = []
    for s in cached_sessions[:number_sessions]:
        aggregated_sessions.append({
            "session_id": s.get("session_id", s.get("id")),
            "started_at": s.get("started_at"),
            "original_text": s.get("original_text", ""),
            "translated_text": s.get("translated_text", ""),
            "language_source": s.get("language_source"),
            "language_target": s.get("language_target"),
        })

    return aggregated_sessions



# -----------------------
# GET AUDIOS
# -----------------------
@router.get("/get_audios")
async def get_audios(
    session_id: str,
    request: Request,
    user=Depends(get_current_user)
):
    """
    Return all audio files available for a given session in storage.
    Always fetches from Supabase storage.
    """
    supabase: AsyncClient = request.app.state.supabase

    try:
        files = await supabase.storage.from_("echonote_bucket").list(path=f"{session_id}/")
        if not files:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"No audio files found for session {session_id}")

        urls = [
            await supabase.storage.from_("echonote_bucket").get_public_url(f"{session_id}/{f['name']}")
            for f in files
        ]
        return {"session_id": session_id, "audio_urls": urls}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching audio files: {str(e)}")



@router.get("/stream_audio/{session_id}")
async def stream_audio(
    session_id: str,
    request: Request,
    user=Depends(get_current_user)
):
    """
    Stream a specific audio file from Supabase for an authenticated user.
    """
    supabase: AsyncClient = request.app.state.supabase

    # Optional: check that this session belongs to the user
    session_resp = await supabase.table("sessions").select("user_id").eq("id", session_id).single().execute()
    if not session_resp.data or session_resp.data["user_id"] != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    try:
        # Download audio file from Supabase
        file_path = f"{session_id}/merged.flac"
        audio_file = await supabase.storage.from_("echonote_bucket").download(file_path)
        if not audio_file:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Audio file not found")

        async def iter_file():
            io_bytes = io.BytesIO(audio_file)
            chunk_size = 64*1024
            while chunk := io_bytes.read(chunk_size):
                yield chunk

        # Stream the file
        return StreamingResponse(iter_file(), media_type="audio/flac")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error streaming audio: {str(e)}")