import abc
from app.services.llm.models import LLMRequest, LLMResponse, LLMCapabilities

class LLMProvider(abc.ABC):
    @abc.abstractmethod
    def provider_name(self) -> str:
        ...

    @abc.abstractmethod
    def model_name(self) -> str:
        ...

    @abc.abstractmethod
    def capabilities(self) -> LLMCapabilities:
        ...

    @abc.abstractmethod
    async def complete(self, request: LLMRequest) -> LLMResponse:
        ...
