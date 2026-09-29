from fastapi import APIRouter, Depends
from typing import List
from app.core.security import get_current_user
from app.models.schemas import DocumentResponse, DocumentDraftCreate, DocumentUpdate
from app.services import document_service

router = APIRouter()

@router.post("/draft", response_model=DocumentResponse)
async def create_document_draft(draft_create: DocumentDraftCreate, user = Depends(get_current_user)):
    return await document_service.create_document_draft(user.id, draft_create)

@router.get("/{document_id}", response_model=DocumentResponse)
def get_document(document_id: str, user = Depends(get_current_user)):
    return document_service.get_document(user.id, document_id)

@router.patch("/{document_id}", response_model=DocumentResponse)
def update_document(document_id: str, doc_update: DocumentUpdate, user = Depends(get_current_user)):
    return document_service.update_document(user.id, document_id, doc_update)

@router.get("/application/{application_id}", response_model=List[DocumentResponse])
def get_application_documents(application_id: str, user = Depends(get_current_user)):
    return document_service.get_application_documents(user.id, application_id)

@router.get("/{document_id}/versions")
def get_document_versions(document_id: str, user = Depends(get_current_user)):
    return document_service.get_document_versions(user.id, document_id)

@router.get("/versions/{version_id}")
def get_document_version(version_id: str, user = Depends(get_current_user)):
    return document_service.get_document_version(user.id, version_id)
