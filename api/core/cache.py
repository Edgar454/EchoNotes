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

async def init_redis(redis_host: str|None , redis_password:str , ssl: bool=True)-> Redis:
    """Initialize async Redis client (call this once on app startup)."""
    if not redis_host:
        logging.error("Missing Redis configuration: REDIS_URL not found.")
        raise ValueError("Missing Redis configuration.")
    
    if ssl:
        redis_client = Redis(
                  host= redis_host,
                  port=6379,
                  password=redis_password,
                  ssl=ssl
                )
    else: 
        redis_client = Redis(
                  host= redis_host,
                  port=6379
                )

    # test the connection
    try:
        await redis_client.ping()
        logging.info("✅ Connected to Redis successfully.")
    except Exception as e:
        logging.error(f"❌ Failed to connect to Redis: {e}")
        raise
    
    return redis_client
    

# --------------------------
# TRANSCRIPT CACHE FUNCTIONS
# --------------------------

async def cache_transcript(
    redis_client:Redis ,
    user_id: str,
    transcript_id: str,
    session_id: str,
    start_time: datetime,
    original_text: str,
    translated_text: str
) -> None:
    """Cache transcript chunk in Redis."""
    user_key = f"user:{user_id}"
    session_key = f"session:{session_id}"
    value = {
        "transcript_id": transcript_id,
        "start_time": start_time,
        "original_text": original_text,
        "translated_text": translated_text
    }
    await redis_client.hset(user_key , session_key, json.dumps(value))
    await redis_client.expire(user_key, 86400)
    


async def get_cached_transcript(redis_client: Redis, user_id: str, session_id: str) -> dict:
    """Retrieve cached transcript for a specific session."""
    user_key = f"user:{user_id}"
    session_key = f"session:{session_id}"
    data = await redis_client.hget(user_key, session_key)
    return json.loads(data) if data else {}



