from app.clients.supabase_client import get_supabase_client
from app.models.schemas import DocumentDraftCreate, DocumentUpdate
from app.core.errors import APIError
from typing import Dict, Any, cast, List
import uuid

async def create_document_draft(user_id: str, draft_create: DocumentDraftCreate):
    supabase = get_supabase_client()

    # 1. Fetch Application -> Opportunity
    app_res = supabase.table("applications").select("opportunity_id").eq("id", str(draft_create.application_id)).eq("user_id", user_id).execute()
    app_data = cast(List[Dict[str, Any]], app_res.data)
    if not app_data:
        raise APIError("NOT_FOUND", "Application not found", 404)
    opp_id = app_data[0]["opportunity_id"]

    # 2. Fetch Opportunity
    opp_res = supabase.table("opportunities").select("*").eq("id", opp_id).execute()
    opp_data = cast(List[Dict[str, Any]], opp_res.data)
    opportunity = opp_data[0] if opp_data else {}

    # 3. Fetch Profile
    prof_res = supabase.table("profiles").select("*").eq("user_id", user_id).execute()
    prof_data = cast(List[Dict[str, Any]], prof_res.data)
    profile = prof_data[0] if prof_data else {}

    # 4. Fetch Match/Fit Analysis
    match_res = supabase.table("opportunity_matches").select("analysis_json").eq("opportunity_id", opp_id).eq("user_id", user_id).execute()
    match_data = cast(List[Dict[str, Any]], match_res.data)
    fit_analysis = match_data[0].get("analysis_json", {}) if match_data else {}

    # 5. Invoke Document Agent
    from app.agents.document import DocumentAgent
    agent = DocumentAgent()
    task_input = {
        "document_kind": draft_create.kind,
        "instruction": draft_create.instruction,
        "application_id": str(draft_create.application_id)
    }

    result = await agent.execute(
        profile=profile,
        opportunity=opportunity,
        fit_analysis=fit_analysis,
        user_id=user_id,
        task_input=task_input
    )

    saved_doc = result.get("saved_document")
    if not saved_doc:
        raise APIError("INTERNAL_ERROR", "Failed to save generated document", 500)

    return saved_doc

def get_document(user_id: str, document_id: str):
    supabase = get_supabase_client()
    res = supabase.table("documents").select("*").eq("id", document_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Document not found.", 404)
    return cast(Dict[str, Any], res.data[0])

def update_document(user_id: str, document_id: str, doc_update: DocumentUpdate):
    supabase = get_supabase_client()

    # Fetch existing to increment version
    existing = get_document(user_id, document_id)

    # Save current version to history before updating
    version_data = {
        "document_id": document_id,
        "user_id": user_id,
        "content": existing["content"],
        "version": existing["version"]
    }
    supabase.table("document_versions").insert(version_data).execute()

    new_version = existing["version"] + 1

    update_data = {
        "content": doc_update.content,
        "version": new_version
    }
    res = supabase.table("documents").update(update_data).eq("id", document_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Document not found.", 404)
    return cast(Dict[str, Any], res.data[0])

def get_application_documents(user_id: str, application_id: str):
    supabase = get_supabase_client()
    app_res = supabase.table("applications").select("id").eq("id", application_id).eq("user_id", user_id).execute()
    if not app_res.data:
        raise APIError("NOT_FOUND", "Application not found.", 404)
        
    res = supabase.table("documents").select("*").eq("application_id", application_id).eq("user_id", user_id).order("updated_at", desc=True).execute()
    return cast(list[Dict[str, Any]], res.data)

def save_generated_document(user_id: str, application_id: str, kind: str, title: str, content: str) -> Dict[str, Any]:
    """Save a generated document draft, preserving versions if it exists."""
    supabase = get_supabase_client()

    # Check if a document of this kind for this application already exists
    res = supabase.table("documents").select("*").eq("user_id", user_id).eq("application_id", application_id).eq("kind", kind).execute()

    if res.data:
        # Document exists, update it and increment version
        existing = cast(Dict[str, Any], res.data[0])
        new_version = existing.get("version", 0) + 1

        version_data = {
            "document_id": existing["id"],
            "user_id": user_id,
            "content": existing["content"],
            "version": existing.get("version", 0)
        }
        supabase.table("document_versions").insert(version_data).execute()

        update_data = {
            "title": title,
            "content": content,
            "version": new_version,
            "is_draft": True
        }
        update_res = supabase.table("documents").update(update_data).eq("id", existing["id"]).eq("user_id", user_id).execute()
        if not update_res.data:
            raise APIError("INTERNAL_ERROR", "Failed to update generated document.", 500)
        return cast(Dict[str, Any], update_res.data[0])
    else:
        # Create new
        db_data = {
            "user_id": user_id,
            "application_id": application_id,
            "kind": kind,
            "title": title,
            "content": content,
            "version": 1,
            "is_draft": True
        }
        insert_res = supabase.table("documents").insert(db_data).execute()
        if not insert_res.data:
            raise APIError("INTERNAL_ERROR", "Failed to insert generated document.", 500)
        return cast(Dict[str, Any], insert_res.data[0])

def get_document_versions(user_id: str, document_id: str):
    supabase = get_supabase_client()
    # Verify ownership of document first
    get_document(user_id, document_id)
    
    res = supabase.table("document_versions").select("*").eq("document_id", document_id).eq("user_id", user_id).order("version", desc=True).execute()
    return res.data

def get_document_version(user_id: str, version_id: str):
    supabase = get_supabase_client()
    res = supabase.table("document_versions").select("*").eq("id", version_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Version not found.", 404)
    return res.data[0]
