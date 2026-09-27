import logging
import asyncio
from typing import Any
from app.services.search.base import SearchProvider
from app.services.search.models import SearchRequest, SearchResponse
from app.services.search.errors import SearchRateLimitError, SearchTimeoutError, SearchUnavailableError

logger = logging.getLogger(__name__)

class RetrySearchProviderWrapper(SearchProvider):
    def __init__(self, provider: SearchProvider, max_retries: int = 3, base_delay: float = 1.0):
        self._provider = provider
        self.max_retries = max_retries
        self.base_delay = base_delay

    def provider_name(self) -> str:
        return self._provider.provider_name()

    def capabilities(self) -> Any:
        return self._provider.capabilities()

    async def search(self, request: SearchRequest) -> SearchResponse:
        retries = 0
        while True:
            try:
                return await self._provider.search(request)
            except (SearchRateLimitError, SearchTimeoutError, SearchUnavailableError) as e:
                if retries >= self.max_retries:
                    raise
                
                delay = self.base_delay * (2 ** retries)
                logger.warning(
                    f"SearchProvider transient error ({e.__class__.__name__}). Retrying in {delay}s (attempt {retries + 1}/{self.max_retries})"
                )
                await asyncio.sleep(delay)
                retries += 1
