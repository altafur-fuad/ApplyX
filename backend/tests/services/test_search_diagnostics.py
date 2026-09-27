import pytest
import asyncio
from app.services.search.diagnostics import get_safe_search_diagnostics, SearchProviderState
from app.services.search.factory import get_search_provider
from app.services.search.models import SearchRequest, SearchOptions
from app.services.search.errors import SearchConfigurationError

@pytest.fixture(autouse=True)
def reset_search_provider_cache():
    import app.services.search.factory as factory
    from app.core.config import get_settings
    get_settings.cache_clear()
    factory._provider_cache = None
    yield
    factory._provider_cache = None
    get_settings.cache_clear()

def test_mock_search_diagnostics_local(monkeypatch):
    monkeypatch.setenv("SEARCH_PROVIDER", "mock")
    diagnostics = get_safe_search_diagnostics()
    
    assert diagnostics["provider"] == "mock"
    assert diagnostics["state"] == SearchProviderState.READY_LOCAL
    assert diagnostics["configured"] is True
    assert diagnostics["credentials_present"] is False
    assert diagnostics["base_url_configured"] is False
    assert diagnostics["capabilities"]["web_search"] is True

def test_tavily_search_diagnostics_missing_key(monkeypatch):
    monkeypatch.setenv("SEARCH_PROVIDER", "tavily")
    monkeypatch.delenv("SEARCH_API_KEY", raising=False)
    
    diagnostics = get_safe_search_diagnostics()
    
    assert diagnostics["provider"] == "tavily"
    assert diagnostics["state"] == SearchProviderState.CONFIG_INVALID
    assert diagnostics["configured"] is True
    assert diagnostics["credentials_present"] is False
    assert "Tavily API key missing" in diagnostics["error"]

def test_tavily_search_diagnostics_valid(monkeypatch):
    monkeypatch.setenv("SEARCH_PROVIDER", "tavily")
    monkeypatch.setenv("SEARCH_API_KEY", "tvly-test-key")
    monkeypatch.setenv("SEARCH_BASE_URL", "https://api.tavily.com")
    
    diagnostics = get_safe_search_diagnostics()
    
    assert diagnostics["provider"] == "tavily"
    assert diagnostics["state"] == SearchProviderState.READY_LOCAL
    assert diagnostics["configured"] is True
    assert diagnostics["credentials_present"] is True
    assert diagnostics["base_url_configured"] is True

@pytest.mark.asyncio
async def test_mock_search_request(monkeypatch):
    monkeypatch.setenv("SEARCH_PROVIDER", "mock")
    provider = get_search_provider()
    
    request = SearchRequest(query="test query")
    response = await provider.search(request)
    
    assert len(response.results) == 1
    assert response.results[0].title == "Mock Result for test query"
    assert response.results[0].source_name == "mock_provider"

def test_fallback_search_provider(monkeypatch):
    monkeypatch.setenv("SEARCH_PROVIDER", "unknown_provider")
    monkeypatch.setenv("SEARCH_FALLBACK_PROVIDER", "mock")
    
    # Should fallback silently to mock
    provider = get_search_provider()
    assert provider.provider_name() == "mock"

def test_fallback_search_provider_disabled(monkeypatch):
    monkeypatch.setenv("SEARCH_PROVIDER", "unknown_provider")
    monkeypatch.setenv("SEARCH_FALLBACK_PROVIDER", "mock")
    
    with pytest.raises(SearchConfigurationError):
        get_search_provider(disable_fallback=True)
