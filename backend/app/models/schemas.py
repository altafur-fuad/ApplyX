from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from uuid import UUID

# Profiles
class ProfileBase(BaseModel):
    full_name: Optional[str] = None
    headline: Optional[str] = None
    bio: Optional[str] = None
    education_level: Optional[str] = None
    department: Optional[str] = None
    location: Optional[str] = None
    work_preference: Optional[str] = None
    skills: List[str] = Field(default_factory=list)
    links: Dict[str, str] = Field(default_factory=dict)

class ProfileUpdate(ProfileBase):
    pass

class ProfileResponse(ProfileBase):
    id: UUID
    user_id: UUID
    created_at: datetime
    updated_at: datetime

# Goals
class GoalCreate(BaseModel):
    title: str
    raw_goal: str
    structured_constraints: Dict[str, Any] = Field(default_factory=dict)

class GoalUpdate(BaseModel):
    title: Optional[str] = None
    raw_goal: Optional[str] = None
    structured_constraints: Optional[Dict[str, Any]] = None
    status: Optional[str] = None

class GoalResponse(BaseModel):
    id: UUID
    user_id: UUID
    title: str
    raw_goal: str
    structured_constraints_json: Dict[str, Any]
    status: str
    created_at: datetime
    updated_at: datetime

# Opportunities
class OpportunityResponse(BaseModel):
    id: UUID
    source_name: str
    source_url: str
    external_id: Optional[str] = None
    title: str
    organization: str
    type: str
    location: Optional[str] = None
    remote_status: Optional[str] = None
    deadline: Optional[datetime] = None
    description: Optional[str] = None
    requirements_json: List[Any] = Field(default_factory=list)
    compensation_text: Optional[str] = None
    fetched_at: datetime
    created_at: datetime
    updated_at: datetime

class PaginatedOpportunities(BaseModel):
    items: List[OpportunityResponse]
    next_cursor: Optional[str] = None

# Applications
class ApplicationCreate(BaseModel):
    opportunity_id: UUID
    status: str = "draft"

class ApplicationUpdate(BaseModel):
    status: Optional[str] = None
    notes: Optional[str] = None
    next_action_at: Optional[datetime] = None

class ApplicationResponse(BaseModel):
    id: UUID
    user_id: UUID
    opportunity_id: UUID
    status: str
    notes: Optional[str] = None
    submitted_at: Optional[datetime] = None
    next_action_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
