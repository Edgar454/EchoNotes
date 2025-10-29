from typing import AsyncGenerator
import asyncio
import uuid
from datetime import datetime
from fastapi import APIRouter, WebSocket, WebSocketDisconnect 
from api.core.utils import transcribe_and_translate
from api.core.utils import ConnectionManager
from api.core.utils import finalize_session
from api.core.storage import ( start_session, start_transcript)
from api.routes.auth_utils import authenticate_websocket

router = APIRouter()


manager = ConnectionManager()


@router.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: int):
    """Main real-time WebSocket entrypoint."""
    user = await authenticate_websocket(websocket)
    if not user:
        return  # closed already

    user_id = user.id

    # get the language from the query parameters
    query = websocket.query_params
    source_language = query.get("source", "fr")
    target_language = query.get("target", "en")

    await manager.connect(websocket, client_id)

    # ---- Initialize session ----
    session_id = str(uuid.uuid4())
    start_time = datetime.now()

    supabase = websocket.app.state.supabase
    redis_client = websocket.app.state.redis_client 


    await start_session(supabase , session_id, user_id, start_time, source_language, target_language)

    chunk_index = 0 

    # Create async generator that yields chunks from the websocket
    async def audio_stream() -> AsyncGenerator[bytes, None]:
        try:
            while True:
                chunk = await websocket.receive_bytes()
                yield chunk
        except WebSocketDisconnect:
            return

    try:
        async for chunk , transcription, translation in transcribe_and_translate(audio_stream(), source_language, target_language):

            # Persist asynchronously
            asyncio.create_task(start_transcript(
                supabase,
                audio_bytes=chunk,  # adapt if you want to store files
                transcript_id=str(uuid.uuid4()),
                session_id=session_id,
                chunk_index=chunk_index,
                start_time=datetime.now(),
                original_text=transcription,
                translated_text=translation
            ))

            # Send to client
            await manager.send_message(websocket, transcription, translation)
            chunk_index += 1

    finally:
        print(f"[Session End] Client {client_id} closed WebSocket — finalizing session {session_id}...")
        await finalize_session(supabase, redis_client, session_id, user_id)
        manager.disconnect(client_id)
        print(f"[Session End] Session {session_id} finalized successfully.")

