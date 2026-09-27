from datetime import datetime, timezone
from app.services.search.base import SearchProvider
from app.services.search.models import SearchRequest, SearchResponse, SearchResult, SearchCapabilities

class MockSearchProvider(SearchProvider):
    def provider_name(self) -> str:
        return "mock"

    def capabilities(self) -> SearchCapabilities:
        return SearchCapabilities(
            web_search=True,
            content_snippets=True,
            raw_content=True,
            domain_filter=True,
            advanced_search=False
        )

    async def search(self, request: SearchRequest) -> SearchResponse:
        return SearchResponse(
            results=[
                SearchResult(
                    title=f"Mock Result for {request.query}",
                    url="https://mock.example.com",
                    snippet="This is a mock search result snippet.",
                    source_name="mock_provider",
                    retrieved_at=datetime.now(timezone.utc)
                )
            ]
        )
