import pytest
import httpx
from app.services.search.providers.tavily import TavilySearchProvider
from app.services.search.models import SearchRequest, SearchOptions
from app.services.search.errors import (
    SearchAuthenticationError, SearchRateLimitError, 
    SearchTimeoutError, SearchUnavailableError, SearchInvalidResponseError
)

@pytest.fixture(autouse=True)
def no_network(monkeypatch):
    def block_request(*args, **kwargs):
        raise RuntimeError("Real network call detected in tests!")
    monkeypatch.setattr("httpx.AsyncClient.post", block_request)

@pytest.mark.asyncio
async def test_tavily_success(monkeypatch):
    provider = TavilySearchProvider(api_key="fake")
    
    class MockResponse:
        status_code = 200
        def json(self):
            return {
                "results": [
                    {"title": "Test Result", "url": "http://test.com", "content": "Test snippet"}
                ]
            }
            
    async def mock_post(*args, **kwargs):
        return MockResponse()
    
    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)
    
    request = SearchRequest(query="test", options=SearchOptions())
    response = await provider.search(request)
    
    assert len(response.results) == 1
    assert response.results[0].title == "Test Result"

@pytest.mark.asyncio
async def test_tavily_auth_error(monkeypatch):
    provider = TavilySearchProvider(api_key="fake")
    
    class MockResponse:
        status_code = 401
            
    async def mock_post(*args, **kwargs):
        return MockResponse()
    
    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)
    
    request = SearchRequest(query="test", options=SearchOptions())
    with pytest.raises(SearchAuthenticationError):
        await provider.search(request)

@pytest.mark.asyncio
async def test_tavily_rate_limit(monkeypatch):
    provider = TavilySearchProvider(api_key="fake")
    
    class MockResponse:
        status_code = 429
            
    async def mock_post(*args, **kwargs):
        return MockResponse()
    
    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)
    
    request = SearchRequest(query="test", options=SearchOptions())
    with pytest.raises(SearchRateLimitError):
        await provider.search(request)

@pytest.mark.asyncio
async def test_tavily_timeout(monkeypatch):
    provider = TavilySearchProvider(api_key="fake")
    
    async def mock_post(*args, **kwargs):
        raise httpx.TimeoutException("timeout")
    
    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)
    
    request = SearchRequest(query="test", options=SearchOptions())
    with pytest.raises(SearchTimeoutError):
        await provider.search(request)

@pytest.mark.asyncio
async def test_tavily_server_error(monkeypatch):
    provider = TavilySearchProvider(api_key="fake")
    
    class MockResponse:
        status_code = 502
            
    async def mock_post(*args, **kwargs):
        return MockResponse()
    
    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)
    
    request = SearchRequest(query="test", options=SearchOptions())
    with pytest.raises(SearchUnavailableError):
        await provider.search(request)

@pytest.mark.asyncio
async def test_tavily_malformed_response(monkeypatch):
    provider = TavilySearchProvider(api_key="fake")
    
    class MockResponse:
        status_code = 200
        def json(self):
            raise ValueError("Invalid JSON")
            
    async def mock_post(*args, **kwargs):
        return MockResponse()
    
    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)
    
    request = SearchRequest(query="test", options=SearchOptions())
    with pytest.raises(SearchInvalidResponseError):
        await provider.search(request)
