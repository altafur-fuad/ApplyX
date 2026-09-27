from app.clients.supabase_client import get_supabase_client
from app.core.errors import APIError
from typing import Optional, Dict, Any, cast

def get_opportunities(
    limit: int = 20, 
    cursor: Optional[str] = None,
    q: Optional[str] = None,
    opportunity_type: Optional[str] = None,
    location: Optional[str] = None,
    remote: Optional[bool] = None,
    status: Optional[str] = None
):
    supabase = get_supabase_client()
    query = supabase.table("opportunities").select("*").limit(limit)
    if cursor:
        query = query.lt("id", cursor)
    if q:
        query = query.ilike("title", f"%{q}%")
    if opportunity_type:
        query = query.eq("type", opportunity_type)
    if location:
        query = query.ilike("location", f"%{location}%")
    if remote is not None:
        if remote:
            query = query.eq("remote_status", "remote")
        else:
            query = query.neq("remote_status", "remote")
    
    res = query.execute()
    items = cast(list[Dict[str, Any]], res.data)
    next_cursor = items[-1]["id"] if items else None
    return {"items": items, "next_cursor": next_cursor}

def get_opportunity(opportunity_id: str):
    supabase = get_supabase_client()
    res = supabase.table("opportunities").select("*").eq("id", opportunity_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Opportunity not found.", 404)
    return cast(Dict[str, Any], res.data[0])

def get_opportunity_match(opportunity_id: str):
    # Retrieve the opportunity to verify it exists
    get_opportunity(opportunity_id)
    # Return placeholder match since we do not store matches yet
    return {
        "eligibility_status": "likely_eligible",
        "fit_reasons": ["Matches your requested job type."],
        "missing_requirements": [],
        "evidence": [
            {
                "claim": "Role matches your query.",
                "source_url": None
            }
        ]
    }

def save_opportunity(user_id: str, opportunity_id: str):
    supabase = get_supabase_client()
    get_opportunity(opportunity_id) # Verify existence
    try:
        res = supabase.table("saved_opportunities").insert(
            {"user_id": user_id, "opportunity_id": opportunity_id}
        ).execute()
        return cast(Dict[str, Any], res.data[0])
    except Exception as e:
        if "duplicate" in str(e).lower() or "unique" in str(e).lower():
            raise APIError("CONFLICT", "Opportunity already saved.", 409)
        raise APIError("INTERNAL_ERROR", "Failed to save opportunity.", 500)
