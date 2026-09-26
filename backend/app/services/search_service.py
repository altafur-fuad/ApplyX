import abc
from typing import Any, Dict, List

class SearchProvider(abc.ABC):
    @abc.abstractmethod
    async def search(self, query: str) -> List[Dict[str, Any]]:
        ...

class MockSearchProvider(SearchProvider):
    async def search(self, query: str) -> List[Dict[str, Any]]:
        return [
            {
                "title": f"Mock Result for {query}",
                "organization": "Mock Org",
                "url": "https://mock.example.com",
                "source_name": "mock_provider",
                "snippet": "This is a mock search result snippet.",
                "type": "internship"
            }
        ]

class WebSearchProvider(SearchProvider):
    def __init__(self, api_key: str):
        self.api_key = api_key

    async def search(self, query: str) -> List[Dict[str, Any]]:
        # In a real implementation this would call Tavily, Serper, Google, etc.
        # For Phase 4 we just use a basic mock implementation.
        return [
            {
                "title": f"Web Result for {query}",
                "organization": "Web Org",
                "url": "https://web.example.com",
                "source_name": "web_provider",
                "snippet": "Real web result snippet.",
                "type": "internship"
            }
        ]

_provider = None

def get_search_provider() -> SearchProvider:
    global _provider
    if _provider is None:
        from app.core.config import get_settings
        _provider = MockSearchProvider()
    return _provider

def set_search_provider(provider: SearchProvider) -> None:
    global _provider
    _provider = provider
