from fastapi import WebSocket, status , HTTPException , Request , Depends 
from fastapi.security import OAuth2PasswordBearer
from supabase import AsyncClient
import logging


# --- OAuth2PasswordBearer instance ---
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/signin")

# ---- Dependency to get Supabase client from lifespan ----
def get_supabase_client(request: Request) -> AsyncClient:
    supabase: AsyncClient = request.app.state.supabase
    if not supabase:
        raise HTTPException(status_code=500, detail="Supabase client not initialized.")
    return supabase


# ---- Helper: authenticate the user ----
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    supabase: AsyncClient = Depends(get_supabase_client),
):
    """Verify the Bearer token and return the user if valid."""

    try:
        user_response = await supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid or expired token.")
        return user
    except Exception as e:
        logging.error(f"Auth error: {e}")
        raise HTTPException(status_code=401, detail="Invalid or expired token.")
    

async def authenticate_websocket(websocket: WebSocket):
    """Authenticate a websocket connection using the same logic as get_current_user()."""
    token = websocket.headers.get("authorization")
    if not token or not token.startswith("Bearer "):
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return None

    access_token = token.split(" ")[1]

    try:
        supabase: AsyncClient = websocket.app.state.supabase
        user_response = await supabase.auth.get_user(access_token)
        user = user_response.user
        if not user:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return None
        return user
    except Exception as e:
        logging.error(f"WebSocket auth failed: {e}")
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR)
        return None



