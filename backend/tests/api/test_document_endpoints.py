import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock, AsyncMock
from app.main import app
import uuid
import json
from app.services.llm.models import LLMResponse, LLMUsage
from app.agents.models import DocumentGenerationResult, GeneratedSection

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_supabase_client():
    import app.clients.supabase_client as sc
    sc._supabase_client = None
    with patch("app.clients.supabase_client.create_client") as mock_create, \
         patch("app.clients.supabase_client.get_settings") as mock_settings:
        mock_settings.return_value = MagicMock(supabase_url="http://test", supabase_service_role_key="test")
        yield mock_create.return_value

def test_document_generation(mock_supabase_client):
    user_id = str(uuid.uuid4())
    app_id = str(uuid.uuid4())
    opp_id = str(uuid.uuid4())
    
    # Mock auth
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock

    # Mock DB selects
    mock_eq = MagicMock()
    mock_supabase_client.table.return_value.select.return_value.eq.return_value = mock_eq
    mock_eq.eq.return_value = mock_eq
    
    mock_eq.execute.side_effect = [
        MagicMock(data=[{"opportunity_id": opp_id}]),  # app_res
        MagicMock(data=[{"id": opp_id, "title": "Test Opp"}]),  # opp_res
        MagicMock(data=[{"user_id": user_id, "full_name": "Test User"}]),  # prof_res
        MagicMock(data=[{"analysis_json": {"score": 90}}]),  # match_res
        MagicMock(data=[]) # save_generated_document -> check if exists
    ]
    
    # Mock DB insert
    doc_id = str(uuid.uuid4())
    mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(
        data=[{"id": doc_id, "user_id": user_id, "application_id": app_id, "kind": "resume", "title": "Draft", "content": "test", "version": 1, "is_draft": True, "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}]
    )

    # Mock LLM provider
    mock_provider = AsyncMock()
    mock_result = DocumentGenerationResult(
        kind="resume",
        title="Resume Draft",
        content="Test summary",
        generated_sections=[GeneratedSection(title="Summary", content="Test summary", uncertainty_warnings=None)]
    )
    mock_provider.complete.return_value = LLMResponse(
        content=mock_result.model_dump_json(),
        usage=LLMUsage(input_tokens=10, output_tokens=10, total_tokens=20),
        parsed=mock_result,
        model="mock-model"
    )

    with patch("app.agents.document.get_llm_provider", return_value=mock_provider):
        res = client.post(
            "/api/v1/documents/draft",
            json={"application_id": app_id, "kind": "resume", "instruction": "Make it good"},
            headers={"Authorization": "Bearer valid_token"}
        )

    if res.status_code != 200:
        print(res.json())
    assert res.status_code == 200
    assert res.json()["id"] == doc_id
    assert mock_provider.complete.called

def test_document_editing_and_versioning(mock_supabase_client):
    user_id = str(uuid.uuid4())
    doc_id = str(uuid.uuid4())
    
    # Mock auth
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock

    # Mock fetching existing document (get_document)
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(
        data=[{"id": doc_id, "content": "old content", "version": 1, "user_id": user_id, "application_id": str(uuid.uuid4()), "kind": "resume", "title": "t", "is_draft": True, "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}]
    )
    
    # Mock update
    mock_supabase_client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(
        data=[{"id": doc_id, "content": "new content", "version": 2, "user_id": user_id, "application_id": str(uuid.uuid4()), "kind": "resume", "title": "t", "is_draft": True, "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}]
    )

    res = client.patch(
        f"/api/v1/documents/{doc_id}",
        json={"content": "new content"},
        headers={"Authorization": "Bearer valid_token"}
    )

    assert res.status_code == 200
    assert res.json()["version"] == 2
    assert res.json()["content"] == "new content"

def test_get_document_versions(mock_supabase_client):
    user_id = str(uuid.uuid4())
    doc_id = str(uuid.uuid4())
    
    # Mock auth
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock

    # get_document check ownership
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(
        data=[{"id": doc_id}]
    )
    
    # get_document_versions
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(
        data=[{"id": "v1", "version": 1}, {"id": "v2", "version": 2}]
    )

    res = client.get(f"/api/v1/documents/{doc_id}/versions", headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200
    assert len(res.json()) == 2

def test_get_document_version(mock_supabase_client):
    user_id = str(uuid.uuid4())
    version_id = str(uuid.uuid4())
    
    # Mock auth
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock

    # get_document_version
    mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(
        data=[{"id": version_id, "document_id": str(uuid.uuid4()), "user_id": user_id, "content": "historical content", "version": 1, "created_at": "2026-01-01T00:00:00Z"}]
    )

    res = client.get(f"/api/v1/documents/versions/{version_id}", headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200
    assert res.json()["content"] == "historical content"
