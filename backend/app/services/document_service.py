from app.clients.supabase_client import get_supabase_client
from app.models.schemas import DocumentDraftCreate, DocumentUpdate
from app.core.errors import APIError
from typing import Dict, Any, cast
import uuid

def create_document_draft(user_id: str, draft_create: DocumentDraftCreate):
    supabase = get_supabase_client()

    # In a real scenario, this might trigger an async agent run.
    # For now we create a mock document synchronously for the MVP UI to function.
    db_data = {
        "user_id": user_id,
        "application_id": str(draft_create.application_id),
        "kind": draft_create.kind,
        "title": f"Draft {draft_create.kind.replace('_', ' ').title()}",
        "content": f"This is an auto-generated draft based on: {draft_create.instruction}",
        "version": 1,
        "is_draft": True
    }
    res = supabase.table("documents").insert(db_data).execute()
    if not res.data:
        raise APIError("INTERNAL_ERROR", "Failed to create document.", 500)
    return cast(Dict[str, Any], res.data[0])

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
    new_version = existing["version"] + 1

    update_data = {
        "content": doc_update.content,
        "version": new_version
    }
    res = supabase.table("documents").update(update_data).eq("id", document_id).eq("user_id", user_id).execute()
    if not res.data:
        raise APIError("NOT_FOUND", "Document not found.", 404)
    return cast(Dict[str, Any], res.data[0])

def save_generated_document(user_id: str, application_id: str, kind: str, title: str, content: str) -> Dict[str, Any]:
    """Save a generated document draft, preserving versions if it exists."""
    supabase = get_supabase_client()

    # Check if a document of this kind for this application already exists
    res = supabase.table("documents").select("*").eq("user_id", user_id).eq("application_id", application_id).eq("kind", kind).execute()

    if res.data:
        # Document exists, update it and increment version
        existing = cast(Dict[str, Any], res.data[0])
        new_version = existing.get("version", 0) + 1
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
