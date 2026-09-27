from app.clients.supabase_client import get_supabase_client
from app.models.schemas import GoalCreate, GoalUpdate
from app.core.errors import APIError
from typing import Dict, Any, cast

def create_goal(user_id: str, goal: GoalCreate):
    supabase = get_supabase_client()
    data = goal.model_dump()
    db_data = {
        "user_id": user_id,
        "title": data["title"],
        "raw_goal": data["raw_goal"],
        "structured_constraints_json": data.get("structured_constraints", {})
    }
    res = supabase.table("goals").insert(db_data).execute()
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to create goal.", 500)
    return cast(Dict[str, Any], res.data[0])

def get_goals(user_id: str):
    supabase = get_supabase_client()
    res = supabase.table("goals").select("*").eq("user_id", user_id).execute()
    return res.data

def get_goal(user_id: str, goal_id: str):
    supabase = get_supabase_client()
    res = supabase.table("goals").select("*").eq("id", goal_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Goal not found.", 404)
    return cast(Dict[str, Any], res.data[0])

def update_goal(user_id: str, goal_id: str, goal_update: GoalUpdate):
    supabase = get_supabase_client()
    update_data = goal_update.model_dump(exclude_unset=True)
    if "structured_constraints" in update_data:
        update_data["structured_constraints_json"] = update_data.pop("structured_constraints")
        
    res = supabase.table("goals").update(update_data).eq("id", goal_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Goal not found.", 404)
    return cast(Dict[str, Any], res.data[0])
