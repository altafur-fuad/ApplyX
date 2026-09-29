from app.clients.supabase_client import get_supabase_client
from app.core.errors import APIError
from typing import Dict, Any, cast

def get_pending_approvals(user_id: str):
    supabase = get_supabase_client()
    res = supabase.table("approvals").select("*").eq("user_id", user_id).eq("status", "pending").execute()
    return res.data

def _update_status(user_id: str, approval_id: str, status: str):
    supabase = get_supabase_client()
    
    # Check if pending
    res = supabase.table("approvals").select("status").eq("id", approval_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Approval not found.", 404)
    item = cast(Dict[str, Any], res.data[0])
    if item["status"] != "pending":
        raise APIError("APPROVAL_INVALID", f"Approval is not pending (current status: {item['status']}).", 422)
    
    update_data = {"status": status}
    from datetime import datetime, timezone
    now_iso = datetime.now(timezone.utc).isoformat()
    if status == "approved":
        update_data["approved_at"] = now_iso
    elif status == "rejected":
        update_data["rejected_at"] = now_iso
        
    res = supabase.table("approvals").update(update_data).eq("id", approval_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Approval not found.", 404)
    return cast(Dict[str, Any], res.data[0])

def approve(user_id: str, approval_id: str):
    return _update_status(user_id, approval_id, "approved")

def reject(user_id: str, approval_id: str):
    return _update_status(user_id, approval_id, "rejected")
