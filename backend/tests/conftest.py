import os
import pytest
from app.core.config import get_settings

# Force offline/mock configuration for all normal pytest runs
os.environ["LLM_PROVIDER"] = "mock"
os.environ["SEARCH_PROVIDER"] = "mock"

# Clear settings cache in case it was already loaded
get_settings.cache_clear()

@pytest.fixture(autouse=True)
def force_mock_providers(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "llm_provider", "mock")
    monkeypatch.setattr(settings, "search_provider", "mock")
    # clear real keys from settings to prevent accidentally hitting external endpoints
    monkeypatch.setattr(settings, "llm_api_key", None)
    monkeypatch.setattr(settings, "openai_api_key", None)
    monkeypatch.setattr(settings, "gemini_api_key", None)

@pytest.fixture(autouse=True)
def mock_supabase_client(monkeypatch):
    """Global mock for Supabase client to prevent HTTP calls in offline tests."""
    from unittest.mock import MagicMock
    mock_client = MagicMock()

    # Setup mock chain: supabase.table().insert().execute()
    mock_table = MagicMock()
    mock_client.table.return_value = mock_table

    mock_query = MagicMock()
    mock_table.insert.return_value = mock_query
    mock_table.update.return_value = mock_query
    mock_table.select.return_value = mock_query

    mock_eq = MagicMock()
    mock_query.eq.return_value = mock_eq

    # Return fake data with an id so that code trying to read res.data[0]["id"] succeeds
    mock_res = MagicMock()
    mock_res.data = [{"id": "mock-uuid"}]

    mock_query.execute.return_value = mock_res
    mock_eq.execute.return_value = mock_res

    # Patch get_supabase_client wherever it's used
    monkeypatch.setattr("app.services.agent_run_service.get_supabase_client", lambda: mock_client)
    monkeypatch.setattr("app.services.agent_event_service.get_supabase_client", lambda: mock_client)
    monkeypatch.setattr("app.services.agent_task_service.get_supabase_client", lambda: mock_client)
    monkeypatch.setattr("app.services.tool_call_service.get_supabase_client", lambda: mock_client)
    monkeypatch.setattr("app.services.goal_service.get_supabase_client", lambda: mock_client)
    monkeypatch.setattr("app.services.profile_service.get_supabase_client", lambda: mock_client)
    monkeypatch.setattr("app.services.document_service.get_supabase_client", lambda: mock_client)
