import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from app.main import app
import uuid

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_supabase_client():
    import app.clients.supabase_client as sc
    sc._supabase_client = None
    with patch("app.clients.supabase_client.create_client") as mock_create, \
         patch("app.clients.supabase_client.get_settings") as mock_settings:
        mock_settings.return_value = MagicMock(supabase_url="http://test", supabase_service_role_key="test")
        yield mock_create.return_value

def test_auth_no_token():
    res = client.get("/api/v1/profiles/me")
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "AUTH_REQUIRED"

def test_auth_malformed_token(mock_supabase_client):
    mock_supabase_client.auth.get_user.side_effect = Exception("Invalid JWT")
    res = client.get("/api/v1/profiles/me", headers={"Authorization": "Bearer bad_token"})
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "AUTH_REQUIRED"

def test_auth_valid_token(mock_supabase_client):
    user_id = str(uuid.uuid4())
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock
    
    mock_supabase_client.table().select().eq().execute.return_value = MagicMock(data=[{"id": str(uuid.uuid4()), "user_id": user_id, "skills_json": [], "links_json": {}, "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}])
    
    res = client.get("/api/v1/profiles/me", headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200
    assert res.json()["user_id"] == user_id

def test_profile_update(mock_supabase_client):
    user_id = str(uuid.uuid4())
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock
    
    mock_supabase_client.table().select().eq().execute.return_value = MagicMock(data=[])
    mock_supabase_client.table().insert().execute.return_value = MagicMock(data=[{"id": str(uuid.uuid4()), "user_id": user_id, "full_name": "Test", "skills_json": [], "links_json": {}, "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}])
    
    res = client.put("/api/v1/profiles/me", json={"full_name": "Test"}, headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200
    assert res.json()["full_name"] == "Test"

def test_goals(mock_supabase_client):
    user_id = str(uuid.uuid4())
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock
    
    goal_id = str(uuid.uuid4())
    mock_supabase_client.table().insert().execute.return_value = MagicMock(data=[{"id": goal_id, "user_id": user_id, "title": "G1", "raw_goal": "rg", "structured_constraints_json": {}, "status": "active", "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}])
    
    # Create goal
    res = client.post("/api/v1/goals", json={"title": "G1", "raw_goal": "rg"}, headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200
    
    # List goals
    mock_supabase_client.table().select().eq().execute.return_value = MagicMock(data=[{"id": goal_id, "user_id": user_id, "title": "G1", "raw_goal": "rg", "structured_constraints_json": {}, "status": "active", "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}])
    res = client.get("/api/v1/goals", headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200
    assert len(res.json()) == 1

def test_opportunities(mock_supabase_client):
    opp_id = str(uuid.uuid4())
    mock_supabase_client.table().select().limit().execute.return_value = MagicMock(data=[{"id": opp_id, "source_name": "test", "source_url": "http", "title": "title", "organization": "org", "type": "type", "requirements_json": [], "fetched_at": "2026-01-01T00:00:00Z", "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}])
    
    # Read is public
    res = client.get("/api/v1/opportunities")
    assert res.status_code == 200
    assert len(res.json()["items"]) == 1

def test_save_opportunity(mock_supabase_client):
    user_id = str(uuid.uuid4())
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock
    
    opp_id = str(uuid.uuid4())
    mock_supabase_client.table().select().eq().execute.return_value = MagicMock(data=[{"id": opp_id}])
    mock_supabase_client.table().insert().execute.return_value = MagicMock(data=[{"user_id": user_id, "opportunity_id": opp_id}])
    
    res = client.post(f"/api/v1/opportunities/{opp_id}/save", headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200

def test_applications(mock_supabase_client):
    user_id = str(uuid.uuid4())
    user_mock = MagicMock()
    user_mock.user.id = user_id
    mock_supabase_client.auth.get_user.return_value = user_mock
    
    opp_id = str(uuid.uuid4())
    app_id = str(uuid.uuid4())
    
    mock_supabase_client.table().select().eq().execute.return_value = MagicMock(data=[{"id": opp_id}])
    mock_supabase_client.table().insert().execute.return_value = MagicMock(data=[{"id": app_id, "user_id": user_id, "opportunity_id": opp_id, "status": "draft", "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"}])
    
    res = client.post("/api/v1/applications", json={"opportunity_id": opp_id}, headers={"Authorization": "Bearer valid_token"})
    assert res.status_code == 200
    assert res.json()["status"] == "draft"

