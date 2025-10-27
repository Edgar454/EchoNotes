import os
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from api.core.storage import init_supabase
from api.core.cache import  init_redis
from api.routes.websocket import manager

load_dotenv()

REDIS_URL = os.getenv("REDIS_HOST")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

@asynccontextmanager
async def lifespan(app):
    try:
        # Startup code if needed
        print("App starting up...")
        app.state.supabase = await init_supabase(SUPABASE_URL , SUPABASE_KEY)
        app.state.redis_client = await init_redis(REDIS_HOST ,REDIS_PASSWORD)
        yield
    finally:
        # Shutdown logic
        print("App shutting down...")

        # 1️⃣ Disconnect all active WebSocket clients gracefully
        for client_id, websocket in list(manager.active_connections.items()):
            try:
                await websocket.close(code=1001, reason="Server shutdown")
                print(f"Client {client_id} disconnected")
            except Exception as e:
                print(f"Failed to disconnect client {client_id}: {e}")
        manager.active_connections.clear()


        # 3️⃣ Close external connections
        await app.state.redis_client.close() 

        print("Shutdown complete, all resources cleaned up")
