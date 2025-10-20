import os
import asyncio
from datetime import datetime
from supabase import AsyncClient
from pydub import AudioSegment
from tempfile import NamedTemporaryFile
from typing import AsyncGenerator, Tuple
from fastapi import WebSocket
from redis.asyncio import Redis
from api.core.groq_transcription import transcript
from api.core.translator import translate_text
from api.core.cache import  end_cached_session
from api.core.storage import  end_session 

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: int):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: int):
        self.active_connections.pop(client_id, None)

    async def send_message(self, websocket: WebSocket, transcription: str, translation: str):
        await websocket.send_json({
            "transcribed_text": transcription,
            "translated_text": translation
        })

        

async def transcribe_and_translate(
    audio_chunks: AsyncGenerator[bytes, None],
    source_lang: str = "fr",
    target_lang: str = "en"
) -> AsyncGenerator[Tuple[bytes, str, str], None]:
    """
    Stream audio chunks, transcribe and translate each,
    yielding (chunk, transcription, translation) in order.
    Uses a bounded queue to keep producer/consumer in sync.
    """
    queue: asyncio.Queue = asyncio.Queue(maxsize=3)  # limit memory

    async def producer():
        async for chunk in audio_chunks:
            transcription = await transcript(chunk, source_language=source_lang)
            await queue.put((chunk, transcription))
        await queue.put(None)  # sentinel to signal end

    async def consumer():
        while True:
            item = await queue.get()
            if item is None:
                break
            chunk, transcription = item
            translation = await translate_text(transcription, source_lang, target_lang)
            yield chunk, transcription, translation

    producer_task = asyncio.create_task(producer())

    # Consume and yield results
    async for result in consumer():
        yield result

    # Wait for producer to finish (in case queue still has items)
    await producer_task



async def fetch_and_merge_session_audio(supabase: AsyncClient, session_id: str):
    """
    Download all audio chunks from Supabase for a session,
    merge them into a single FLAC file, delete the chunks,
    and upload the final merged file.
    """
    bucket = supabase.storage.from_("echonote_bucket")
    chunks = await bucket.list(path=f"{session_id}/")

    if not chunks:
        print(f"No chunks found for session {session_id}")
        return

    # Sort numerically if filenames are digits (e.g. 0.flac, 1.flac)
    chunks = sorted(
        chunks,
        key=lambda c: int(c["name"].split(".")[0]) if c["name"].split(".")[0].isdigit() else c["name"]
    )

    merged_audio = None
    merged_file_path = f"{session_id}_merged.flac"

    for chunk_info in chunks:
        chunk_path = f"{session_id}/{chunk_info['name']}"
        chunk_resp = await bucket.download(chunk_path)

        # Extract bytes correctly depending on client version
        if not chunk_resp:
            print(f"⚠️ Failed to download chunk {chunk_info['name']}")
            continue

        # Save chunk temporarily
        with NamedTemporaryFile(delete=False, suffix=".flac") as tmp_file:
            tmp_file.write(chunk_resp)
            tmp_file_path = tmp_file.name

        # Load audio and append
        segment = AudioSegment.from_file(tmp_file_path, format="flac")
        merged_audio = segment if merged_audio is None else merged_audio + segment

        os.remove(tmp_file_path)
        await bucket.remove([chunk_path])

    # Export and upload merged file
    if merged_audio:
        merged_audio.export(merged_file_path, format="flac")

        with open(merged_file_path, "rb") as f:
            await bucket.upload(f"{session_id}/merged.flac", f)

        os.remove(merged_file_path)
        print(f"✅ Session {session_id} merged and uploaded successfully")
    else:
        print(f"⚠️ No valid audio chunks merged for session {session_id}")


async def finalize_session(supabase:AsyncClient, redis_client:Redis , session_id: str, client_id: int):
    """
    Triggered automatically when the WebSocket is closed.
    Ends cached session, marks it as complete, and merges audio.
    """
    end_time = datetime.now()
    await end_cached_session(redis_client, session_id, end_time)
    await end_session(supabase, session_id, end_time)

    try:
        await fetch_and_merge_session_audio(supabase, session_id)
        print(f"✅ Session {session_id}: audio merged successfully.")
    except Exception as e:
        print(f"⚠️ Session {session_id}: audio merge failed: {e}")

    