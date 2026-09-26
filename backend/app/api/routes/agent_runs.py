"""
Agent Run API routes.

POST   /v1/agent-runs           — create and queue a new agent run
GET    /v1/agent-runs/{run_id}  — get run status (owner only)
GET    /v1/agent-runs/{run_id}/events — get ordered events (owner only)
POST   /v1/agent-runs/{run_id}/cancel — cancel a run (owner only)
"""

from __future__ import annotations

from typing import List
from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends

from app.agents.models import (
    AgentEventResponse,
    AgentEventsListResponse,
    AgentRunCreateRequest,
    AgentRunResponse,
    RunStatus,
)
from app.core.errors import APIError
from app.core.security import get_current_user
from app.services import agent_run_service, agent_event_service, goal_service

router = APIRouter()


@router.post("", response_model=AgentRunResponse, status_code=201)
def create_agent_run(
    body: AgentRunCreateRequest,
    background_tasks: BackgroundTasks,
    user=Depends(get_current_user),
):
    """
    Create a new agent run for the given goal.

    - Verifies the goal belongs to the authenticated user.
    - Creates the run with status QUEUED.
    - Does NOT hold the request open for full execution.
    """
    # Verify goal ownership — raises NOT_FOUND if not owned
    goal = goal_service.get_goal(user.id, str(body.goal_id))

    # Create the run
    run = agent_run_service.create_agent_run(
        user_id=str(user.id),
        goal_id=str(body.goal_id),
        status=RunStatus.QUEUED.value,
    )

    # Schedule background execution (will be wired in later phases)
    # For now, the run stays QUEUED until a worker picks it up.
    # background_tasks.add_task(_execute_run, run["id"], str(user.id), goal)

    return run


@router.get("/{run_id}", response_model=AgentRunResponse)
def get_agent_run(run_id: UUID, user=Depends(get_current_user)):
    """Return the current state of an agent run (owner only)."""
    return agent_run_service.get_agent_run(str(run_id), str(user.id))


@router.get("/{run_id}/events", response_model=AgentEventsListResponse)
def get_agent_run_events(run_id: UUID, user=Depends(get_current_user)):
    """Return ordered, user-safe events for a run (owner only)."""
    events = agent_event_service.get_events_for_run(str(run_id), str(user.id))

    formatted = []
    for ev in events:
        formatted.append(
            AgentEventResponse(
                id=ev["id"],
                event_type=ev["event_type"],
                message=ev.get("message"),
                payload=ev.get("payload_json", {}),
                task_id=ev.get("task_id"),
                created_at=ev["created_at"],
            )
        )
    return AgentEventsListResponse(events=formatted)


@router.post("/{run_id}/cancel", response_model=AgentRunResponse)
def cancel_agent_run(run_id: UUID, user=Depends(get_current_user)):
    """Cancel a running agent run (owner only)."""
    return agent_run_service.cancel_agent_run(str(run_id), str(user.id))
