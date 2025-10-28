import json
from redis.asyncio import Redis
from datetime import datetime
from typing import Optional, List
import logging

# Optional logging setup
logging.basicConfig(level=logging.INFO)



# -----------------------
# INIT / CONNECTION
# -----------------------

async def init_redis(redis_host: str|None , redis_password:str)-> Redis:
    """Initialize async Redis client (call this once on app startup)."""
    if not redis_host:
        logging.error("Missing Redis configuration: REDIS_URL not found.")
        raise ValueError("Missing Redis configuration.")
    
    redis_client = Redis(
                  host= redis_host,
                  port=6379,
                  password=redis_password,
                  ssl=True
                )

    # test the connection
    try:
        await redis_client.ping()
        logging.info("✅ Connected to Redis successfully.")
    except Exception as e:
        logging.error(f"❌ Failed to connect to Redis: {e}")
        raise
    
    return redis_client
    


# -----------------------
# SESSION CACHE FUNCTIONS
# -----------------------

async def cache_session(redis_client:Redis , session_id: str, user_id: str, started_at: datetime, language_source: str, language_target: str) -> None:
    """Cache session metadata in Redis."""
    key = f"session:{session_id}"
    value = {
        "user_id": user_id,
        "started_at": started_at.isoformat(),
        "language_source": language_source,
        "language_target": language_target
    }
    await redis_client.set(key, json.dumps(value))
    await redis_client.expire(key, 86400)  # expire after 1 day


async def get_cached_session(redis_client:Redis ,session_id: str) -> Optional[dict]:
    """Retrieve cached session metadata."""
    key = f"session:{session_id}"
    data = await redis_client.get(key)
    if data:
        return json.loads(data)
    return None


async def end_cached_session(redis_client:Redis ,session_id: str, ended_at: datetime) -> None:
    """Update cached session end time."""
    session = await get_cached_session(redis_client ,session_id)
    if session:
        session["ended_at"] = ended_at.isoformat()
        await redis_client.set(f"session:{session_id}", json.dumps(session))
        await redis_client.expire(f"session:{session_id}", 86400)


# --------------------------
# TRANSCRIPT CACHE FUNCTIONS
# --------------------------

async def cache_transcript(
    redis_client:Redis ,
    transcript_id: str,
    session_id: str,
    chunk_index: int,
    start_time: datetime,
    original_text: str,
    translated_text: str
) -> None:
    """Cache transcript chunk in Redis."""
    key = f"transcript:{session_id}:{chunk_index}"
    value = {
        "transcript_id": transcript_id,
        "start_time": start_time.isoformat(),
        "original_text": original_text,
        "translated_text": translated_text
    }
    await redis_client.set(key, json.dumps(value))
    await redis_client.expire(key, 86400)
    
    
async def get_session_keys(redis: Redis, pattern: str) -> List[str]:
    """Scan and return all keys matching the pattern."""
    cursor = "0"
    keys = []
    while True:
        cursor, batch = await redis.scan(cursor=cursor, match=pattern)
        keys.extend(k.decode() if isinstance(k, bytes) else k for k in batch)
        if cursor == "0":
            break
    return keys


async def get_cached_transcripts(redis_client: Redis, session_id: str) -> List[dict]:
    """Retrieve all cached transcripts for a session."""
    pattern = f"transcript:{session_id}:*"
    keys = await get_session_keys(redis_client, pattern)
    transcripts = []
    for key in sorted(keys):
        data = await redis_client.get(key)
        if data:
            transcripts.append(json.loads(data))
    return transcripts


async def end_cached_transcript(redis_client:Redis ,transcript_id: str, session_id: str, chunk_index: int, end_time: datetime) -> None:
    """Update end time for a cached transcript chunk."""
    key = f"transcript:{session_id}:{chunk_index}"
    transcript = await redis_client.get(key)
    if transcript:
        transcript_data = json.loads(transcript)
        transcript_data["end_time"] = end_time.isoformat()
        await redis_client.set(key, json.dumps(transcript_data))
        await redis_client.expire(key, 86400)
