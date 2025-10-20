import os
from datetime import datetime
from supabase import acreate_client, AsyncClient
from dotenv import load_dotenv
import logging

# getting the env variables
load_dotenv()
SUPABASE_BUCKET = os.getenv('SUPABASE_BUCKET','echonote_bucket')

# Optional logging setup
logging.basicConfig(level=logging.INFO)

async def init_supabase(supabase_url:str|None , supabase_key:str|None )->AsyncClient:
    if not supabase_url or not supabase_key:
        logging.error("Missing Supabase configuration: SUPABASE_URL or SUPABASE_KEY not found.")
        raise ValueError("Missing Supabase configuration.")

    return await acreate_client(supabase_url, supabase_key)



async def start_session(
    supabase:AsyncClient,
    session_id: str,
    user_id: str,
    started_at: datetime,
    language_source: str,
    language_target: str,
    log: bool = False
) -> None:
    """Create a new session entry in the database."""
    try:
        started_iso = started_at.isoformat()
        response = await supabase.table("sessions").insert({
            "id": session_id,
            "user_id": user_id,
            "started_at": started_iso,
            "language_source": language_source,
            "language_target": language_target
        }).execute()
        if log:
            logging.info(f"Session created: {response}")
    except Exception as e:
        logging.error(f"Error saving the session: {e}")


async def start_transcript(
    supabase:AsyncClient,
    audio_bytes: bytes,
    transcript_id: str,
    session_id: str,
    chunk_index: int,
    start_time: datetime,
    original_text: str,
    translated_text: str,
    log: bool = False
) -> None:
    """Insert transcript metadata and upload audio chunk to Supabase Storage."""
    try:
        start_iso = start_time.isoformat()
        # Insert transcript metadata
        db_response = await supabase.table("transcripts").insert({
            "transcript_id": transcript_id,
            "session_id": session_id,
            "chunk_index": chunk_index,
            "start_time": start_iso,
            "original_text": original_text,
            "translated_text": translated_text,
            "created_at": datetime.now().isoformat()
        }).execute()
        if log:
            logging.info(f"Transcript metadata saved: {db_response}")


        # Upload audio chunk
        storage_response = await supabase.storage.from_(SUPABASE_BUCKET).upload(
                file=audio_bytes,
                path=f"{session_id}/{chunk_index}",
            )
        if log:
            logging.info(f"Audio uploaded: {storage_response}")

    except Exception as e:
        logging.error(f"Error saving the transcript: {e}")


async def end_session(supabase:AsyncClient, session_id: str, ended_at: datetime, log: bool = False) -> None:
    """Update session end time."""
    try:
        ended_iso = ended_at.isoformat()
        response = await supabase.table("sessions").update({
            "ended_at": ended_iso
        }).eq("id", session_id).execute()
        if log:
            logging.info(f"Session ended: {response}")
    except Exception as e:
        logging.error(f"Error ending session: {e}")


async def end_transcript(supabase:AsyncClient, transcript_id: str, end_time: datetime, log: bool = False) -> None:
    """Update transcript end time."""
    try:
        end_iso = end_time.isoformat()
        response = await supabase.table("transcripts").update({
            "end_time": end_iso
        }).eq("id", transcript_id).execute()
        if log:
            logging.info(f"Transcript ended: {response}")
    except Exception as e:
        logging.error(f"Error ending transcript: {e}")
