from fastapi import APIRouter, Depends
from typing import List
from app.core.security import get_current_user
from app.models.schemas import ApprovalResponse
from app.services import approval_service

router = APIRouter()

@router.get("", response_model=List[ApprovalResponse])
def get_pending_approvals(user = Depends(get_current_user)):
    return approval_service.get_pending_approvals(user.id)

@router.post("/{approval_id}/approve", response_model=ApprovalResponse)
def approve(approval_id: str, user = Depends(get_current_user)):
    return approval_service.approve(user.id, approval_id)

@router.post("/{approval_id}/reject", response_model=ApprovalResponse)
def reject(approval_id: str, user = Depends(get_current_user)):
    return approval_service.reject(user.id, approval_id)
