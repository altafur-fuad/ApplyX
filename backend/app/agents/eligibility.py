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

class EligibilityConclusion(BaseModel):
    requirement: str
    is_met: bool
    reason: str
    evidence_reference: str
    uncertainty_state: str # "confirmed", "uncertain", "insufficient_evidence"

class EligibilityResultModel(BaseModel):
    opportunity_title: str
    eligibility_status: str # "clearly_eligible", "clearly_not_eligible", "uncertain", "insufficient_evidence"
    conclusions: List[EligibilityConclusion]

class EligibilityListModel(BaseModel):
    results: List[EligibilityResultModel]
    evidence_claims: List[str]

class EligibilityAgent(BaseEligibilityAgent):
    async def execute(
        self,
        opportunities: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        provider = get_llm_provider()

        system_prompt = """You are the ApplyX Eligibility Agent.
Your job is to compare opportunity requirements against the authenticated user's profile and retrieved evidence.
Distinguish between clearly eligible, clearly not eligible, uncertain, and insufficient evidence.
Do not infer eligibility from missing data.
For every eligibility conclusion, preserve the reason, the relevant opportunity field (requirement), an evidence reference (if available), and the uncertainty state ("confirmed", "uncertain", "insufficient_evidence").
For eligibility_status, use ONLY: "clearly_eligible", "clearly_not_eligible", "uncertain", "insufficient_evidence".
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
            conclusions = []
            for c in r.get("conclusions", []):
                conclusions.append({
                    "requirement": c.get("requirement"),
                    "is_met": c.get("is_met"),
                    "reason": c.get("reason"),
                    "evidence_reference": c.get("evidence_reference"),
                    "uncertainty_state": c.get("uncertainty_state"),
                })

            out_results.append({
                "opportunity_title": r.get("opportunity_title"),
                "eligibility_status": r.get("eligibility_status"),
                "conclusions": conclusions,
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
    return EligibilityAgent()
