"""
Tool call persistence service.

Handles CRUD for tool_calls table.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, cast

from app.clients.supabase_client import get_supabase_client
from app.core.errors import APIError

logger = logging.getLogger(__name__)


def create_tool_call(
    agent_run_id: str,
    tool_name: str,
    risk_level: str,
    *,
    task_id: str | None = None,
    input_json: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
    """Insert a new tool_call row."""
    supabase = get_supabase_client()
    data: Dict[str, Any] = {
        "agent_run_id": agent_run_id,
        "tool_name": tool_name,
        "risk_level": risk_level,
    }
    if task_id is not None:
        data["task_id"] = task_id
    if input_json is not None:
        data["input_json"] = input_json

    res = supabase.table("tool_calls").insert(data).execute()
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to create tool call.", 500)
    return cast(Dict[str, Any], res.data[0])


def update_tool_call(
    tool_call_id: str,
    update_data: Dict[str, Any],
) -> Dict[str, Any]:
    """Update a tool call by id."""
    supabase = get_supabase_client()
    res = (
        supabase.table("tool_calls")
        .update(update_data)
        .eq("id", tool_call_id)
        .execute()
    )
    if not res.data:
        raise APIError("NOT_FOUND", "Tool call not found.", 404)
    return cast(Dict[str, Any], res.data[0])


def get_tool_calls_for_run(agent_run_id: str) -> List[Dict[str, Any]]:
    """Return all tool calls for a run, ordered by created_at."""
    supabase = get_supabase_client()
    res = (
        supabase.table("tool_calls")
        .select("*")
        .eq("agent_run_id", agent_run_id)
        .order("created_at")
        .execute()
    )
    return cast(List[Dict[str, Any]], res.data or [])
