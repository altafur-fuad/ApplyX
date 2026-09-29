import httpx
import hashlib
from typing import List, Tuple, Dict, Any
from datetime import datetime, timezone
import logging
import urllib.parse

from app.services.opportunity.connectors.base import OpportunityConnector
from app.services.search.models import SearchResult
from app.agents.models import Evidence, EvidenceStatus, ConfidenceLevel
from app.services.search.errors import SearchError, SearchTimeoutError

logger = logging.getLogger(__name__)

class RemotiveConnector(OpportunityConnector):
    def source_identity(self) -> str:
        return "remotive"

    def base_url(self) -> str:
        return "https://remotive.com/api/remote-jobs"

    async def fetch(self, query: str, limit: int = 10) -> List[SearchResult]:
        # Remotive supports 'search' query param
        encoded_query = urllib.parse.quote(query)
        url = f"{self.base_url()}?search={encoded_query}&limit={limit}"
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
        except httpx.TimeoutException as e:
            logger.warning(f"Timeout fetching from Remotive: {e}")
            raise SearchTimeoutError("Remotive API timed out.") from e
        except Exception as e:
            logger.warning(f"Error fetching from Remotive: {e}")
            raise SearchError(f"Remotive API error: {e}") from e

        jobs = data.get("jobs", [])
        now = datetime.now(timezone.utc)
        
        results = []
        for job in jobs[:limit]:
            results.append(SearchResult(
                title=job.get("title", ""),
                url=job.get("url", ""),
                snippet=job.get("description", "")[:500], # Keep a snippet, full html in raw_content
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
        location = meta.get("candidate_required_location", "")
        job_type = meta.get("job_type", "full_time").lower()
        url = meta.get("url") or result.url
        raw_description = meta.get("description", "")
        
        content_str = f"{title}::{organization}"
        content_hash = hashlib.sha256(content_str.encode()).hexdigest()[:16]

        opp = {
            "title": title,
            "organization": organization,
            "type": job_type,
            "location": location,
            "remote_status": "remote", # remotive is exclusively remote
            "description": raw_description,
            "requirements": [], # We will parse this in Phase 8C
            "compensation_text": meta.get("salary", ""),
            "source_url": url,
            "source_name": self.source_identity(),
            "external_id": str(meta.get("id", "")),
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
        
        evidence.append(Evidence(
            claim="Role is 100% remote",
            status=EvidenceStatus.CONFIRMED,
            source_url=url,
            retrieved_at=now,
            confidence=ConfidenceLevel.HIGH,
            evidence_type="location_details"
        ).model_dump(mode="json"))
        
        if location:
            evidence.append(Evidence(
                claim=f"Candidate required location: {location}",
                status=EvidenceStatus.CONFIRMED,
                source_url=url,
                retrieved_at=now,
                confidence=ConfidenceLevel.HIGH,
                evidence_type="location_details"
            ).model_dump(mode="json"))
            
        if meta.get("salary"):
            evidence.append(Evidence(
                claim=f"Salary listed as {meta.get('salary')}",
                status=EvidenceStatus.CONFIRMED,
                source_url=url,
                retrieved_at=now,
                confidence=ConfidenceLevel.HIGH,
                evidence_type="compensation_details"
            ).model_dump(mode="json"))

        return opp, evidence
