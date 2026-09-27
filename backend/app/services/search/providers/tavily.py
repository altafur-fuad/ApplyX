import httpx
from datetime import datetime, timezone
from typing import Optional, Any
from app.services.search.base import SearchProvider
from app.services.search.models import SearchRequest, SearchResponse, SearchResult, SearchCapabilities, SearchUsage
from app.services.search.errors import (
    SearchAuthenticationError,
    SearchRateLimitError,
    SearchConfigurationError,
    SearchInvalidResponseError,
    SearchTimeoutError,
    SearchError
)

class TavilySearchProvider(SearchProvider):
    def __init__(self, api_key: str, base_url: Optional[str] = None):
        self.api_key = api_key
        self.base_url = base_url or "https://api.tavily.com"

    def provider_name(self) -> str:
        return "tavily"

    def capabilities(self) -> SearchCapabilities:
        return SearchCapabilities(
            web_search=True,
            content_snippets=True,
            raw_content=True,
            domain_filter=True,
            advanced_search=True
        )

    async def search(self, request: SearchRequest) -> SearchResponse:
        url = f"{self.base_url.rstrip('/')}/search"
        
        payload: dict[str, Any] = {
            "api_key": self.api_key,
            "query": request.query,
            "search_depth": request.options.search_depth,
            "max_results": request.options.max_results,
            "include_raw_content": request.options.include_raw_content
        }
        
        if request.options.include_domains:
            payload["include_domains"] = request.options.include_domains
            
        if request.options.exclude_domains:
            payload["exclude_domains"] = request.options.exclude_domains

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(url, json=payload)
        except httpx.TimeoutException as e:
            raise SearchTimeoutError("Tavily search request timed out.") from e
        except httpx.RequestError as e:
            raise SearchError(f"Tavily network error: {str(e)}") from e

        if response.status_code == 401:
            raise SearchAuthenticationError("Invalid Tavily API key.")
        elif response.status_code == 429:
            raise SearchRateLimitError("Tavily rate limit exceeded.")
        elif response.status_code >= 400:
            raise SearchInvalidResponseError(f"Tavily returned error status {response.status_code}: {response.text}")

        try:
            data = response.json()
        except ValueError as e:
            raise SearchInvalidResponseError("Failed to parse Tavily JSON response.") from e

        results = []
        now = datetime.now(timezone.utc)
        for r in data.get("results", []):
            results.append(SearchResult(
                title=r.get("title", ""),
                url=r.get("url", ""),
                snippet=r.get("content", ""),
                raw_content=r.get("raw_content"),
                source_name=self.provider_name(),
                score=r.get("score"),
                retrieved_at=now,
                provider_metadata=r
            ))

        return SearchResponse(
            results=results,
            usage=SearchUsage(credits_used=None)
        )
