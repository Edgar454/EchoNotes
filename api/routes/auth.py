import logging
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from supabase import AsyncClient
from datetime import datetime
from pydantic import BaseModel , EmailStr
from api.routes.auth_utils import get_current_user , get_supabase_client

router = APIRouter(prefix="/auth", tags=["auth"])

# --- Pydantic schemas ---
class SignUpRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    role: str = "user"


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    role: str | None = None
    avatar_url: str | None = None





# ---- Signup ----
@router.post("/signup")
async def signup(
    signup_request: SignUpRequest,
    supabase: AsyncClient = Depends(get_supabase_client),
):
    """Create a new user and initialize profile."""
    try:
        # Create auth user
        auth_response = await supabase.auth.sign_up({"email": signup_request.email, "password": signup_request.password})
        user = auth_response.user

        # Create profile if auth succeeded
        if user:
            await supabase.table("profiles").insert({
                "id": user.id,
                "full_name": signup_request.full_name,
                "role": "user",
                "avatar_url": "user_avatars/default.png",
                "created_at": datetime.utcnow().isoformat()
            }).execute()

        return {"message": "User registered successfully", "user_id": user.id}
    except Exception as e:
        logging.error(f"Signup error: {e}")
        raise HTTPException(status_code=400, detail=str(e))


# ---- Signin ----
@router.post("/signin")
async def signin(
    form_data: OAuth2PasswordRequestForm = Depends(),
    supabase: AsyncClient = Depends(get_supabase_client),
):
    """Sign in a user and return access + refresh tokens."""
    try:
        auth_response =  await supabase.auth.sign_in_with_password({"email": form_data.username, "password": form_data.password})
        session = auth_response.session

        if not session:
            raise HTTPException(status_code=401, detail="Invalid credentials.")

        return { "access_token": session.access_token, "token_type": "bearer" }

    except Exception as e:
        logging.error(f"Signin error: {e}")
        raise HTTPException(status_code=401, detail="Invalid credentials.")


# ---- Get Profile ----
@router.get("/profile")
async def get_profile(
    current_user=Depends(get_current_user),
    supabase: AsyncClient = Depends(get_supabase_client),
):
    """Fetch profile info for the authenticated user."""
    try:
        user_id = current_user.id
        response = await supabase.table("profiles").select("*").eq("id", user_id).single().execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Profile not found.")
        return response.data
    except Exception as e:
        logging.error(f"Get profile error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ---- Update Profile ----
@router.put("/profile")
async def update_profile(
    update_profile_request:UpdateProfileRequest,
    current_user=Depends(get_current_user),
    supabase: AsyncClient = Depends(get_supabase_client),
):
    """Update the authenticated user’s profile."""
    try:
        user_id = current_user.id
        updates = {}

        if update_profile_request.full_name:
            updates["full_name"] = update_profile_request.full_name
        if update_profile_request.role:
            updates["role"] = update_profile_request.role
        if update_profile_request.avatar_url:
            updates["avatar_url"] = update_profile_request.avatar_url

        if not updates:
            raise HTTPException(status_code=400, detail="No updates provided.")

        response = (
            await supabase.table("profiles")
            .update(updates)
            .eq("id", user_id)
            .execute()
        )

        return {"message": "Profile updated successfully", "data": response}
    except Exception as e:
        logging.error(f"Update profile error: {e}")
        raise HTTPException(status_code=500, detail=str(e))





