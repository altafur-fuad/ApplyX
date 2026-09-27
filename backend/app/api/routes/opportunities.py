from fastapi import APIRouter, Depends, Query
from app.core.security import get_current_user
from app.models.schemas import OpportunityResponse, PaginatedOpportunities
from app.services import opportunity_service
from typing import Optional

router = APIRouter()

@router.get("", response_model=PaginatedOpportunities)
def get_opportunities(
    limit: int = Query(20, ge=1, le=100),
    cursor: Optional[str] = None
):
    return opportunity_service.get_opportunities(limit, cursor)

@router.get("/{opportunity_id}", response_model=OpportunityResponse)
def get_opportunity(opportunity_id: str):
    return opportunity_service.get_opportunity(opportunity_id)

@router.post("/{opportunity_id}/save")
def save_opportunity(opportunity_id: str, user = Depends(get_current_user)):
    return opportunity_service.save_opportunity(user.id, opportunity_id)
