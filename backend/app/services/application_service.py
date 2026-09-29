from app.clients.supabase_client import get_supabase_client
from app.models.schemas import ApplicationCreate, ApplicationUpdate
from app.core.errors import APIError
from app.services.opportunity_service import get_opportunity
from typing import Dict, Any, cast

def _map_application(data: Dict[str, Any]) -> Dict[str, Any]:
    opp = data.pop("opportunities", None)
    if opp:
        data["opportunity_title"] = opp.get("title")
        data["opportunity_organization"] = opp.get("organization")
    return data

def get_applications(user_id: str):
    supabase = get_supabase_client()
    res = supabase.table("applications").select("*, opportunities(title, organization)").eq("user_id", user_id).order("updated_at", desc=True).execute()
    return [_map_application(cast(Dict[str, Any], d)) for d in res.data]

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
    
    # fetch with joined opportunity
    inserted = cast(Dict[str, Any], res.data[0])
    app_id = inserted["id"]
    fetch_res = supabase.table("applications").select("*, opportunities(title, organization)").eq("id", app_id).execute()
    return _map_application(cast(Dict[str, Any], fetch_res.data[0]))

def update_application(user_id: str, app_id: str, app_update: ApplicationUpdate):
    supabase = get_supabase_client()
    update_data = app_update.model_dump(mode='json', exclude_unset=True)
    res = supabase.table("applications").update(update_data).eq("id", app_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Application not found.", 404)
        
    fetch_res = supabase.table("applications").select("*, opportunities(title, organization)").eq("id", app_id).execute()
    return _map_application(cast(Dict[str, Any], fetch_res.data[0]))

def get_application_checklist(user_id: str, app_id: str) -> Dict[str, Any]:
    supabase = get_supabase_client()
    
    app_res = supabase.table("applications").select("*, opportunities(requirements_json)").eq("id", app_id).eq("user_id", user_id).execute()
    if not app_res.data:
        raise APIError("NOT_FOUND", "Application not found.", 404)
        
    app_record = cast(Dict[str, Any], app_res.data[0])
    opp = cast(Dict[str, Any], app_record.get("opportunities") or {})
    reqs = opp.get("requirements_json") or []
    
    docs_res = supabase.table("documents").select("id, kind, title, version").eq("application_id", app_id).eq("user_id", user_id).execute()
    docs = cast(list[Dict[str, Any]], docs_res.data or [])
    
    checklist = []
    
    has_resume = any(d.get("kind") in ("resume", "resume_bullets") for d in docs)
    checklist.append({
        "type": "document",
        "key": "resume",
        "label": "Resume",
        "is_complete": has_resume
    })
    
    has_cover_letter = any(d.get("kind") == "cover_letter" for d in docs)
    checklist.append({
        "type": "document",
        "key": "cover_letter",
        "label": "Cover Letter",
        "is_complete": has_cover_letter
    })
    
    if isinstance(reqs, list):
        for req in reqs:
            checklist.append({
                "type": "requirement",
                "key": req,
                "label": f"Requirement: {req}",
                "is_complete": False
            })
            
    checklist.append({
        "type": "verification",
        "key": "final_verification",
        "label": "Final Verification",
        "is_complete": app_record.get("status") in ("ready", "submitted", "interview", "accepted")
    })
    
    return {"checklist": checklist}
