import abc
from app.services.search.models import SearchRequest, SearchResponse, SearchCapabilities

class SearchProvider(abc.ABC):
    @abc.abstractmethod
    def provider_name(self) -> str:
        ...

    @abc.abstractmethod
    def capabilities(self) -> SearchCapabilities:
        ...

    @abc.abstractmethod
    async def search(self, request: SearchRequest) -> SearchResponse:
        ...
