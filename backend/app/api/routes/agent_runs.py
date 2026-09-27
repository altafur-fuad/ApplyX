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
from app.services import agent_run_service, agent_event_service, goal_service, profile_service
from app.agents.orchestrator import Orchestrator
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

async def _execute_run(run_id: str, user_id: str, goal: dict):
    try:
        # 1. Transition to PLANNING
        agent_run_service.transition_agent_run_status(
            run_id=run_id,
            user_id=user_id,
            new_status=RunStatus.PLANNING,
            current_step="Initializing orchestrator"
        )
        
        # 2. Get Profile
        try:
            profile = profile_service.get_profile(user_id)
        except Exception:
            profile = {}
        
        # 3. Run Orchestrator
        orch = Orchestrator()
        state = await orch.run(
            goal_data=goal,
            profile_data=profile,
            run_id=run_id,
            user_id=user_id
        )
        
        # 4. Save Final State
        final_summary = None
        if state.final_result:
            final_summary = str(state.final_result)
        
        plan_json = None
        if state.plan:
            plan_json = {"tasks": [t.model_dump(mode="json") for t in state.plan.tasks]}
            
        agent_run_service.transition_agent_run_status(
            run_id=run_id,
            user_id=user_id,
            new_status=state.status,
            error_message=state.error,
            final_summary=final_summary,
            plan_json=plan_json,
            current_step="Completed"
        )
        
    except Exception as e:
        import traceback
        logger.error(f"Error in background agent run: {traceback.format_exc()}")
        try:
            agent_run_service.transition_agent_run_status(
                run_id=run_id,
                user_id=user_id,
                new_status=RunStatus.FAILED,
                error_message=str(e),
                current_step="Failed due to exception"
            )
        except:
            pass


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

    # Schedule background execution
    background_tasks.add_task(_execute_run, run["id"], str(user.id), goal)

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
