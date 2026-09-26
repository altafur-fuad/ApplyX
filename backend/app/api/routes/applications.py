from fastapi import APIRouter, Depends
from typing import List
from app.core.security import get_current_user
from app.models.schemas import ApplicationResponse, ApplicationCreate, ApplicationUpdate
from app.services import application_service

router = APIRouter()

@router.post("", response_model=ApplicationResponse)
def create_application(app_create: ApplicationCreate, user = Depends(get_current_user)):
    return application_service.create_application(user.id, app_create)

@router.get("", response_model=List[ApplicationResponse])
def get_applications(user = Depends(get_current_user)):
    return application_service.get_applications(user.id)

@router.patch("/{application_id}", response_model=ApplicationResponse)
def update_application(application_id: str, app_update: ApplicationUpdate, user = Depends(get_current_user)):
    return application_service.update_application(user.id, application_id, app_update)
