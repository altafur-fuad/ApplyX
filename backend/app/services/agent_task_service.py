"""
Agent task persistence service.

Handles CRUD for agent_tasks table.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, cast

from app.clients.supabase_client import get_supabase_client
from app.core.errors import APIError

logger = logging.getLogger(__name__)


def create_agent_task(
    agent_run_id: str,
    agent_type: str,
    name: str,
    *,
    input_json: Dict[str, Any] | None = None,
    parent_task_id: str | None = None,
) -> Dict[str, Any]:
    """Insert a new agent_task row."""
    supabase = get_supabase_client()
    data: Dict[str, Any] = {
        "agent_run_id": agent_run_id,
        "agent_type": agent_type,
        "name": name,
    }
    if input_json is not None:
        data["input_json"] = input_json
    if parent_task_id is not None:
        data["parent_task_id"] = parent_task_id

    res = supabase.table("agent_tasks").insert(data).execute()
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to create agent task.", 500)
    return cast(Dict[str, Any], res.data[0])


def update_agent_task(
    task_id: str,
    update_data: Dict[str, Any],
) -> Dict[str, Any]:
    """Update an agent task by id."""
    supabase = get_supabase_client()
    res = (
        supabase.table("agent_tasks")
        .update(update_data)
        .eq("id", task_id)
        .execute()
    )
    if not res.data:
        raise APIError("NOT_FOUND", "Agent task not found.", 404)
    return cast(Dict[str, Any], res.data[0])


def get_tasks_for_run(agent_run_id: str) -> List[Dict[str, Any]]:
    """Return all tasks for a run, ordered by created_at."""
    supabase = get_supabase_client()
    res = (
        supabase.table("agent_tasks")
        .select("*")
        .eq("agent_run_id", agent_run_id)
        .order("created_at")
        .execute()
    )
    return cast(List[Dict[str, Any]], res.data or [])
