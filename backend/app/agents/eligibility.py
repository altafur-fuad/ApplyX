"""
Eligibility Agent — parses requirements and compares against profile facts.

Returns `insufficient_evidence` when evidence is missing.
Phase 3: deterministic mock implementation.
"""

from __future__ import annotations

import abc
import json
import logging
from typing import Any, Dict, List

from app.agents.models import ConfidenceLevel, Evidence, EvidenceStatus
from app.services.llm_service import get_llm_provider, LLMRequest, LLMMessage
from pydantic import BaseModel

logger = logging.getLogger(__name__)


class BaseEligibilityAgent(abc.ABC):
    @abc.abstractmethod
    async def execute(
        self,
        opportunities: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        ...

class MockEligibilityAgent(BaseEligibilityAgent):
    """Deterministic eligibility analysis for Phase 3."""
    async def execute(
        self,
        opportunities: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
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

class EligibilityResultModel(BaseModel):
    opportunity_title: str
    eligibility_status: str # "confirmed", "likely", "uncertain", "insufficient_evidence"
    met_requirements: List[str]
    missing_requirements: List[str]
    potential_blockers: List[str]
    confidence: str

class EligibilityListModel(BaseModel):
    results: List[EligibilityResultModel]
    evidence_claims: List[str]

class RealLLMEligibilityAgent(BaseEligibilityAgent):
    async def execute(
        self,
        opportunities: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        provider = get_llm_provider()
        
        system_prompt = """You are the ApplyX Eligibility Agent.
Your job is to compare opportunity requirements against the authenticated user's profile and retrieved evidence.
Distinguish between eligible evidence, missing evidence, uncertain requirements, and potential blockers.
Never say "you are definitely eligible" unless evidence establishes it.
For eligibility_status, use ONLY: "confirmed", "likely", "uncertain", "insufficient_evidence".
"""
        user_prompt = f"Profile: {json.dumps(profile)}\nOpportunities: {json.dumps(opportunities)}"
        
        request = LLMRequest(
            messages=[
                LLMMessage(role="system", content=system_prompt),
                LLMMessage(role="user", content=user_prompt)
            ],
            response_model=EligibilityListModel,
            temperature=0.0
        )
        
        response = await provider.complete(request)
        if response.parsed:
            data = response.parsed.model_dump()
        else:
            try:
                data = json.loads(response.content)
            except:
                data = {"results": [], "evidence_claims": []}
                
        # Format back to expected dict format
        out_results = []
        out_evidence = []
        
        for r in data.get("results", []):
            out_results.append({
                "opportunity_title": r.get("opportunity_title"),
                "eligibility_status": r.get("eligibility_status"),
                "met_requirements": r.get("met_requirements"),
                "missing_requirements": r.get("missing_requirements"),
                "potential_blockers": r.get("potential_blockers"),
                "confidence": r.get("confidence", "low"),
            })
            out_evidence.append(
                Evidence(
                    claim=f"Eligibility for {r.get('opportunity_title')}: {r.get('eligibility_status')}",
                    status=EvidenceStatus.UNCERTAIN,
                    confidence=ConfidenceLevel.LOW,
                    evidence_type="eligibility_analysis"
                ).model_dump(mode="json")
            )
            
        return {
            "eligibility_results": out_results,
            "evidence": out_evidence,
        }

def get_eligibility_agent() -> BaseEligibilityAgent:
    provider = get_llm_provider()
    if provider.provider_name() == "mock":
        return MockEligibilityAgent()
    return RealLLMEligibilityAgent()
