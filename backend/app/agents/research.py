"""
Research Agent — searches approved sources and collects opportunity records.

Phase 3: deterministic mock that returns sample opportunity data.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict

from app.agents.models import Evidence, EvidenceStatus, ConfidenceLevel

logger = logging.getLogger(__name__)


class ResearchAgent:
    """
    Deterministic research agent for Phase 3.

    Returns sample opportunities with proper source evidence.
    Never claims an opportunity exists without source evidence.
    """

    def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Simulate research based on constraints.

        Returns opportunities with source URLs and retrieval timestamps.
        """
        constraints = input_data.get("constraints", {})
        skills = constraints.get("skills", [])
        opp_types = constraints.get("opportunity_types", ["internship"])

        now = datetime.now(timezone.utc)

        # Sample deterministic results
        opportunities = [
            {
                "title": f"Sample {opp_types[0].title() if opp_types else 'Opportunity'} - {skills[0] if skills else 'General'}",
                "organization": "Example Corp",
                "type": opp_types[0] if opp_types else "internship",
                "location": "Remote",
                "remote_status": "remote" if constraints.get("remote") else "onsite",
                "source_url": "https://example.com/opportunity/1",
                "source_name": "example_board",
                "fetched_at": now.isoformat(),
                "description": f"A sample opportunity for {', '.join(skills) if skills else 'general applicants'}.",
                "requirements": skills,
            }
        ]

        evidence = [
            Evidence(
                claim=f"Opportunity found: {opportunities[0]['title']}",
                status=EvidenceStatus.CONFIRMED,
                source_url=opportunities[0]["source_url"],
                retrieved_at=now,
                confidence=ConfidenceLevel.HIGH,
                evidence_type="opportunity_listing",
            ).model_dump(mode="json")
        ]

        logger.info(
            "research_complete opportunities_found=%d",
            len(opportunities),
        )

        return {
            "opportunities": opportunities,
            "evidence": evidence,
            "sources_checked": ["example_board"],
        }
