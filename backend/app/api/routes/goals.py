from fastapi import APIRouter, Depends
from typing import List
from app.core.security import get_current_user
from app.models.schemas import GoalResponse, GoalCreate, GoalUpdate
from app.services import goal_service

router = APIRouter()

@router.post("", response_model=GoalResponse)
def create_goal(goal: GoalCreate, user = Depends(get_current_user)):
    return goal_service.create_goal(user.id, goal)

@router.get("", response_model=List[GoalResponse])
def get_goals(user = Depends(get_current_user)):
    return goal_service.get_goals(user.id)

@router.get("/{goal_id}", response_model=GoalResponse)
def get_goal(goal_id: str, user = Depends(get_current_user)):
    return goal_service.get_goal(user.id, goal_id)

@router.patch("/{goal_id}", response_model=GoalResponse)
def update_goal(goal_id: str, goal_update: GoalUpdate, user = Depends(get_current_user)):
    return goal_service.update_goal(user.id, goal_id, goal_update)
