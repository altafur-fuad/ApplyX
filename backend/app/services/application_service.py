from app.clients.supabase_client import get_supabase_client
from app.models.schemas import ApplicationCreate, ApplicationUpdate
from app.core.errors import APIError
from app.services.opportunity_service import get_opportunity
from typing import Dict, Any, cast

def get_applications(user_id: str):
    supabase = get_supabase_client()
    res = supabase.table("applications").select("*").eq("user_id", user_id).execute()
    return res.data

def create_application(user_id: str, app_create: ApplicationCreate):
    supabase = get_supabase_client()
    get_opportunity(str(app_create.opportunity_id))
    db_data = {
        "user_id": user_id,
        "opportunity_id": str(app_create.opportunity_id),
        "status": app_create.status
    }
    res = supabase.table("applications").insert(db_data).execute()
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to create application.", 500)
    return cast(Dict[str, Any], res.data[0])

def update_application(user_id: str, app_id: str, app_update: ApplicationUpdate):
    supabase = get_supabase_client()
    update_data = app_update.model_dump(mode='json', exclude_unset=True)
    res = supabase.table("applications").update(update_data).eq("id", app_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Application not found.", 404)
    return cast(Dict[str, Any], res.data[0])
