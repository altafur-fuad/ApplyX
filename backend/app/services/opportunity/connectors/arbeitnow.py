import httpx
import hashlib
from typing import List, Tuple, Dict, Any
from datetime import datetime, timezone
import logging

from app.services.opportunity.connectors.base import OpportunityConnector
from app.services.search.models import SearchResult
from app.agents.models import Evidence, EvidenceStatus, ConfidenceLevel
from app.services.search.errors import SearchError, SearchTimeoutError

logger = logging.getLogger(__name__)

class ArbeitnowConnector(OpportunityConnector):
    def source_identity(self) -> str:
        return "arbeitnow"

    def base_url(self) -> str:
        return "https://www.arbeitnow.com/api/job-board-api"

    async def fetch(self, query: str, limit: int = 10) -> List[SearchResult]:
        # Arbeitnow API doesn't have a direct search query parameter in the free version.
        # We will fetch the first page and filter in-memory for simplicity.
        url = self.base_url()
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
        except httpx.TimeoutException as e:
            logger.warning(f"Timeout fetching from Arbeitnow: {e}")
            raise SearchTimeoutError("Arbeitnow API timed out.") from e
        except Exception as e:
            logger.warning(f"Error fetching from Arbeitnow: {e}")
            raise SearchError(f"Arbeitnow API error: {e}") from e

        jobs = data.get("data", [])
        now = datetime.now(timezone.utc)
        
        # Filter by query if query exists
        q_lower = query.lower()
        filtered_jobs = []
        for job in jobs:
            if not query or q_lower in job.get("title", "").lower() or q_lower in job.get("company_name", "").lower():
                filtered_jobs.append(job)
                
        results = []
        for job in filtered_jobs[:limit]:
            results.append(SearchResult(
                title=job.get("title", ""),
                url=job.get("url", ""),
                snippet=job.get("description", "")[:500],
                raw_content=job.get("description", ""),
                source_name=self.source_identity(),
                retrieved_at=now,
                provider_metadata=job
            ))
            
        return results

    def normalize(self, result: SearchResult) -> Tuple[Dict[str, Any], List[Dict[str, Any]]]:
        meta = result.provider_metadata or {}
        
        title = meta.get("title") or result.title
        organization = meta.get("company_name", "")
        location = meta.get("location", "")
        remote = meta.get("remote", False)
        url = meta.get("url") or result.url
        raw_description = meta.get("description", "")
        
        content_str = f"{title}::{organization}"
        content_hash = hashlib.sha256(content_str.encode()).hexdigest()[:16]

        opp = {
            "title": title,
            "organization": organization,
            "type": "full_time", # Defaulting as Arbeitnow doesn't clearly split intern/FT in schema
            "location": location,
            "remote_status": "remote" if remote else "onsite",
            "description": raw_description,
            "requirements": [],
            "compensation_text": None,
            "source_url": url,
            "source_name": self.source_identity(),
            "external_id": str(meta.get("slug", "")),
            "content_hash": content_hash,
            "deadline": None,
        }
        
        # Provenance Evidence
        evidence = []
        now = result.retrieved_at or datetime.now(timezone.utc)
        
        evidence.append(Evidence(
            claim=f"Opportunity found: {title} at {organization}",
            status=EvidenceStatus.CONFIRMED,
            source_url=url,
            retrieved_at=now,
            confidence=ConfidenceLevel.HIGH,
            evidence_type="opportunity_listing"
        ).model_dump(mode="json"))
        
        if location:
            evidence.append(Evidence(
                claim=f"Location: {location}",
                status=EvidenceStatus.CONFIRMED,
                source_url=url,
                retrieved_at=now,
                confidence=ConfidenceLevel.HIGH,
                evidence_type="location_details"
            ).model_dump(mode="json"))

        return opp, evidence
