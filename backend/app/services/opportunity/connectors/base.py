import abc
from typing import List, Tuple, Dict, Any

from app.services.search.models import SearchResult

class OpportunityConnector(abc.ABC):
    """
    Abstract base class for opportunity source connectors.
    Enforces a strict contract for fetching and normalizing opportunities.
    """

    @abc.abstractmethod
    def source_identity(self) -> str:
        """Identity of the source (e.g., 'remotive', 'arbeitnow')."""
        pass
        
    @abc.abstractmethod
    def base_url(self) -> str:
        """Base location/URL of the source."""
        pass
        
    @abc.abstractmethod
    async def fetch(self, query: str, limit: int = 10) -> List[SearchResult]:
        """
        Fetch raw results based on query with timeout and error handling.
        Returns a list of SearchResult containing the raw data in provider_metadata.
        """
        pass
        
    @abc.abstractmethod
    def normalize(self, result: SearchResult) -> Tuple[Dict[str, Any], List[Dict[str, Any]]]:
        """
        Normalize a SearchResult into (OpportunityDict, list[EvidenceDict]).
        Must preserve source URL, fetched timestamp, and provenance.
        """
        pass
