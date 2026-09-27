"""
Agent run persistence service.

Handles CRUD for agent_runs table.
Enforces ownership on read/update operations.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, cast

from app.agents.models import RunStatus
from app.clients.supabase_client import get_supabase_client
from app.core.errors import APIError

logger = logging.getLogger(__name__)


def create_agent_run(
    user_id: str,
    goal_id: str,
    *,
    status: str = RunStatus.QUEUED.value,
) -> Dict[str, Any]:
    """Insert a new agent_run row and return it."""
    supabase = get_supabase_client()
    data = {
        "user_id": user_id,
        "goal_id": goal_id,
        "status": status,
    }
    res = supabase.table("agent_runs").insert(data).execute()
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to create agent run.", 500)
    row = cast(Dict[str, Any], res.data[0])
    logger.info("agent_run_created id=%s user=%s", row.get("id"), user_id[:8])
    return row


def get_agent_run(run_id: str, user_id: str) -> Dict[str, Any]:
    """Return the run if it belongs to *user_id*."""
    supabase = get_supabase_client()
    res = (
        supabase.table("agent_runs")
        .select("*")
        .eq("id", run_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not res.data:
        raise APIError("NOT_FOUND", "Agent run not found.", 404)
    return cast(Dict[str, Any], res.data[0])


def update_agent_run(
    run_id: str,
    user_id: str,
    update_data: Dict[str, Any],
) -> Dict[str, Any]:
    """Update an agent run, enforcing ownership."""
    supabase = get_supabase_client()
    res = (
        supabase.table("agent_runs")
        .update(update_data)
        .eq("id", run_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not res.data:
        raise APIError("NOT_FOUND", "Agent run not found.", 404)
    return cast(Dict[str, Any], res.data[0])


def transition_agent_run_status(
    run_id: str,
    user_id: str,
    new_status: RunStatus,
    *,
    error_message: Optional[str] = None,
    final_summary: Optional[str] = None,
    plan_json: Optional[Dict[str, Any]] = None,
    current_step: Optional[str] = None,
) -> Dict[str, Any]:
    """Transition status and optional fields atomically."""
    update: Dict[str, Any] = {"status": new_status.value}
    if error_message is not None:
        update["error_message"] = error_message
    if final_summary is not None:
        update["final_summary"] = final_summary
    if plan_json is not None:
        update["plan_json"] = plan_json
    if current_step is not None:
        update["current_step"] = current_step

    now_iso = datetime.now(timezone.utc).isoformat()
    if new_status == RunStatus.PLANNING:
        update["started_at"] = now_iso
    if new_status in (RunStatus.COMPLETED, RunStatus.FAILED, RunStatus.CANCELLED):
        update["completed_at"] = now_iso

    return update_agent_run(run_id, user_id, update)


def cancel_agent_run(run_id: str, user_id: str) -> Dict[str, Any]:
    """Cancel a run if it is not already in a terminal state."""
    from app.agents.models import TERMINAL_RUN_STATUSES
    run = get_agent_run(run_id, user_id)
    current = RunStatus(run["status"])
    if current in TERMINAL_RUN_STATUSES:
        raise APIError(
            "CONFLICT",
            f"Cannot cancel run in terminal state '{current.value}'.",
            409,
        )
    return transition_agent_run_status(run_id, user_id, RunStatus.CANCELLED)
