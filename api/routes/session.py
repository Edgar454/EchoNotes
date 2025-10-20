import io
from fastapi import APIRouter, Request, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from datetime import datetime
import json
import logging
from api.routes.auth_utils import get_current_user
from api.core.cache import get_cached_transcripts
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
    cached_transcripts = await get_cached_transcripts(redis_client, session_id)
    if cached_transcripts:
        logging.info(f"Cache hit for session {session_id}")
        full_original = " ".join([t.get("original_text", "") for t in cached_transcripts])
        full_translated = " ".join([t.get("translated_text", "") for t in cached_transcripts])
        created_at = cached_transcripts[0].get("start_time", datetime.utcnow().isoformat())
    else:
        logging.info(f"Cache miss for session {session_id}, fetching from Supabase")
        response = await supabase.table("transcripts").select("*").eq("session_id", session_id).order("chunk_index").execute()
        if not response.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"No transcripts found for session {session_id}")
        full_original = " ".join([chunk.get("original_text", "") for chunk in response.data])
        full_translated = " ".join([chunk.get("translated_text", "") for chunk in response.data])
        created_at = response.data[0]["created_at"]

    return {
        "session_id": session_id,
        "user_id": user.id,
        "original_text": full_original.strip(),
        "translated_text": full_translated.strip(),
        "created_at": created_at
    }


# -----------------------
# GET LAST TRANSCRIPTS
# -----------------------
@router.get("/get_last_transcripts")
async def get_last_transcripts(request: Request,user= Depends(get_current_user), number_sessions: int = 10):
    """
    Return the last N session summaries for the authenticated user.
    Each transcript is merged into one entry per session.
    """
    supabase: AsyncClient = request.app.state.supabase
    redis: Redis = request.app.state.redis_client

    # Step 1: Fetch last N sessions from cache or Supabase
    session_keys = await redis.keys(f"session:{user.id}:*")
    cached_sessions = []
    if session_keys:
        for key in sorted(session_keys, reverse=True)[:number_sessions]:
            data = await redis.get(key)
            if data:
                cached_sessions.append(json.loads(data))

    # If we have enough cached sessions, return them
    if len(cached_sessions) >= number_sessions:
        sessions_to_return = cached_sessions[:number_sessions]
    else:
        # Fetch last N sessions from Supabase
        resp = await supabase.table("sessions").select("*").eq("user_id", user.id)\
                        .order("started_at", desc=True).limit(number_sessions).execute()
        sessions_to_return = resp.data or []

    # Step 2: Fetch transcripts for these sessions
    session_ids = [s["id"] for s in sessions_to_return]
    transcripts_resp = await supabase.table("transcripts").select("*")\
                            .in_("session_id", session_ids).order("chunk_index").execute()
    transcripts = transcripts_resp.data or []

    # Step 3: Aggregate transcripts per session
    aggregated_sessions = []
    session_map = {s["id"]: s for s in sessions_to_return}
    for sid in session_ids:
        chunks = [t for t in transcripts if t["session_id"] == sid]
        original = " ".join([c.get("original_text", "") for c in chunks]).strip()
        translated = " ".join([c.get("translated_text", "") for c in chunks]).strip()
        session_data = session_map[sid]

        aggregated_sessions.append({
            "session_id": sid,
            "started_at": session_data.get("started_at"),
            "original_text": original,
            "translated_text": translated,
            "language_source": session_data.get("language_source"),
            "language_target": session_data.get("language_target"),
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