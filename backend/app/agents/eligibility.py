"""
Eligibility Agent — parses requirements and compares against profile facts.

Returns `insufficient_evidence` when evidence is missing.
Phase 3: deterministic mock implementation.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List

from app.agents.models import ConfidenceLevel, Evidence, EvidenceStatus

logger = logging.getLogger(__name__)


class EligibilityAgent:
    """
    Deterministic eligibility analysis for Phase 3.

    Compares opportunity requirements against user profile.
    """

    def execute(
        self,
        opportunities: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Analyze eligibility for each opportunity."""
        user_skills = {
            s.lower()
            for s in (profile.get("skills") or profile.get("skills_json") or [])
        }

        results = []
        evidence: list[dict[str, Any]] = []

        for opp in opportunities:
            requirements = [
                r.lower()
                for r in (opp.get("requirements") or opp.get("requirements_json") or [])
            ]

            met = [r for r in requirements if r in user_skills]
            missing = [r for r in requirements if r not in user_skills]

            if not requirements:
                status = "insufficient_evidence"
                confidence = ConfidenceLevel.INSUFFICIENT
            elif len(met) == len(requirements):
                status = "likely_eligible"
                confidence = ConfidenceLevel.HIGH
            elif len(met) >= len(requirements) * 0.5:
                status = "partially_eligible"
                confidence = ConfidenceLevel.MEDIUM
            else:
                status = "likely_not_eligible"
                confidence = ConfidenceLevel.LOW

            results.append({
                "opportunity_title": opp.get("title", ""),
                "eligibility_status": status,
                "met_requirements": met,
                "missing_requirements": missing,
                "confidence": confidence.value,
            })

            evidence.append(
                Evidence(
                    claim=f"Eligibility for '{opp.get('title', '')}': {status}",
                    status=(
                        EvidenceStatus.CONFIRMED
                        if status in ("likely_eligible", "likely_not_eligible")
                        else EvidenceStatus.UNCERTAIN
                    ),
                    source_url=opp.get("source_url"),
                    confidence=confidence,
                    evidence_type="eligibility_analysis",
                ).model_dump(mode="json")
            )

        logger.info("eligibility_complete count=%d", len(results))

        return {
            "eligibility_results": results,
            "evidence": evidence,
        }
