from fastapi import APIRouter, Depends
from app.core.security import get_current_user
from app.models.schemas import ProfileResponse, ProfileUpdate
from app.services import profile_service

router = APIRouter()

@router.get("/me", response_model=ProfileResponse)
def get_my_profile(user = Depends(get_current_user)):
    return profile_service.get_profile(user.id)

@router.put("/me", response_model=ProfileResponse)
def update_my_profile(profile_update: ProfileUpdate, user = Depends(get_current_user)):
    return profile_service.update_profile(user.id, profile_update)
