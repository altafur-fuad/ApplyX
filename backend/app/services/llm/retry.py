import asyncio
import logging
from app.services.llm.base import LLMProvider
from app.services.llm.models import LLMRequest, LLMResponse, LLMCapabilities
from app.services.llm.errors import (
    LLMRateLimitError, LLMTimeoutError, LLMUnavailableError
)

logger = logging.getLogger(__name__)

class RetryLLMProviderWrapper(LLMProvider):
    def __init__(self, provider: LLMProvider, max_retries: int = 3, base_delay: float = 1.0):
        self._provider = provider
        self.max_retries = max_retries
        self.base_delay = base_delay

    def provider_name(self) -> str:
        return self._provider.provider_name()

    def model_name(self) -> str:
        return self._provider.model_name()

    def capabilities(self) -> LLMCapabilities:
        return self._provider.capabilities()

    async def complete(self, request: LLMRequest) -> LLMResponse:
        retries = 0
        while True:
            try:
                # Provide a hard timeout (60 seconds per request attempt)
                return await asyncio.wait_for(self._provider.complete(request), timeout=60.0)
            except (LLMRateLimitError, LLMTimeoutError, LLMUnavailableError) as e:
                retries += 1
                if retries > self.max_retries:
                    raise
                delay = self.base_delay * (2 ** (retries - 1))
                logger.warning("LLM request failed (attempt %d/%d). Retrying in %.1fs. Error: %s", retries, self.max_retries, delay, e)
                await asyncio.sleep(delay)
