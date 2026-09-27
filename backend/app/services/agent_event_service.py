"""
Agent event persistence service.

Handles CRUD for agent_events table.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, cast

from app.clients.supabase_client import get_supabase_client
from app.core.errors import APIError

logger = logging.getLogger(__name__)


def create_agent_event(
    agent_run_id: str,
    event_type: str,
    *,
    task_id: str | None = None,
    message: str | None = None,
    payload: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
    """Insert a new agent_event row."""
    supabase = get_supabase_client()
    data: Dict[str, Any] = {
        "agent_run_id": agent_run_id,
        "event_type": event_type,
    }
    if task_id is not None:
        data["task_id"] = task_id
    if message is not None:
        data["message"] = message
    if payload is not None:
        data["payload_json"] = payload

    res = supabase.table("agent_events").insert(data).execute()
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to create agent event.", 500)
    return cast(Dict[str, Any], res.data[0])


def get_events_for_run(
    agent_run_id: str,
    user_id: str,
) -> List[Dict[str, Any]]:
    """
    Return ordered events for a run.

    Ownership is enforced by first confirming the run belongs to user_id.
    """
    from app.services.agent_run_service import get_agent_run

    # This will raise NOT_FOUND if ownership fails
    get_agent_run(agent_run_id, user_id)

    supabase = get_supabase_client()
    res = (
        supabase.table("agent_events")
        .select("*")
        .eq("agent_run_id", agent_run_id)
        .order("created_at")
        .execute()
    )
    return cast(List[Dict[str, Any]], res.data or [])
