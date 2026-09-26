from app.clients.supabase_client import get_supabase_client
from app.models.schemas import ProfileUpdate
from app.core.errors import APIError
from typing import Dict, Any, cast

def get_profile(user_id: str):
    supabase = get_supabase_client()
    res = supabase.table("profiles").select("*").eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Profile not found.", 404)
    
    data = cast(Dict[str, Any], res.data[0])
    data["skills"] = data.pop("skills_json", [])
    data["links"] = data.pop("links_json", {})
    return data

def update_profile(user_id: str, profile_update: ProfileUpdate):
    supabase = get_supabase_client()
    update_data = profile_update.model_dump(exclude_unset=True)
    
    if "skills" in update_data:
        update_data["skills_json"] = update_data.pop("skills")
    if "links" in update_data:
        update_data["links_json"] = update_data.pop("links")
        
    res = supabase.table("profiles").select("*").eq("user_id", user_id).execute()
    if not res.data:
        update_data["user_id"] = user_id
        res = supabase.table("profiles").insert(update_data).execute()
    else:
        res = supabase.table("profiles").update(update_data).eq("user_id", user_id).execute()
        
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to update profile.", 500)
        
    data = cast(Dict[str, Any], res.data[0])
    data["skills"] = data.pop("skills_json", [])
    data["links"] = data.pop("links_json", {})
    return data
