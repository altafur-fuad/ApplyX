"""
Profile-Fit Agent — compares opportunity requirements with profile evidence.

Explains matching and missing skills. Never invents experience.
Phase 3: deterministic mock implementation.
"""

from __future__ import annotations

import abc
import json
import logging
from typing import Any, Dict, List
from pydantic import BaseModel
from app.services.llm_service import get_llm_provider, LLMRequest, LLMMessage

logger = logging.getLogger(__name__)


class BaseProfileFitAgent(abc.ABC):
    @abc.abstractmethod
    async def execute(
        self,
        eligibility_results: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        ...

class MockProfileFitAgent(BaseProfileFitAgent):
    """Deterministic profile fit analysis for Phase 3."""
    async def execute(
        self,
        eligibility_results: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        user_skills = set(
            s.lower()
            for s in (profile.get("skills") or profile.get("skills_json") or [])
        )
        user_headline = profile.get("headline", "")
        user_education = profile.get("education_level", "")

        fit_analyses = []

        for result in eligibility_results:
            met = result.get("met_requirements", [])
            missing = result.get("missing_requirements", [])

            fit_reasons = []
            if met:
                fit_reasons.append(
                    f"Profile matches requirements: {', '.join(met)}."
                )
            if user_headline:
                fit_reasons.append(f"Headline: {user_headline}")
            if user_education:
                fit_reasons.append(f"Education: {user_education}")

            gaps = []
            if missing:
                gaps.append(
                    f"Missing skills/requirements: {', '.join(missing)}."
                )

            fit_analyses.append({
                "opportunity_title": result.get("opportunity_title", ""),
                "fit_reasons": fit_reasons,
                "gaps": gaps,
                "overall_fit": "strong" if not missing else ("partial" if met else "weak"),
            })

        logger.info("profile_fit_complete count=%d", len(fit_analyses))

        return {"fit_analyses": fit_analyses}


class ProfileFitResultModel(BaseModel):
    opportunity_title: str
    fit_reasons: List[str]
    gaps: List[str]
    overall_fit: str

class ProfileFitListModel(BaseModel):
    fit_analyses: List[ProfileFitResultModel]

class RealLLMProfileFitAgent(BaseProfileFitAgent):
    """LLM-backed profile fit analysis."""
    async def execute(
        self,
        eligibility_results: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        provider = get_llm_provider()
        
        system_prompt = """You are the ApplyX Profile-Fit Agent.
Compare the user profile to the opportunity eligibility results.
Output matching skills, relevant profile evidence, missing skills, missing evidence, and a fit explanation.
Never invent experience or skills.
"""
        user_prompt = f"Profile: {json.dumps(profile)}\nEligibility: {json.dumps(eligibility_results)}"
        
        request = LLMRequest(
            messages=[
                LLMMessage(role="system", content=system_prompt),
                LLMMessage(role="user", content=user_prompt)
            ],
            response_model=ProfileFitListModel,
            temperature=0.0
        )
        
        response = await provider.complete(request)
        if response.parsed:
            data = response.parsed.model_dump()
        else:
            try:
                data = json.loads(response.content)
            except:
                data = {"fit_analyses": []}
                
        return data

def get_profile_fit_agent() -> BaseProfileFitAgent:
    from app.core.config import get_settings
    if get_settings().openai_api_key:
        return RealLLMProfileFitAgent()
    return MockProfileFitAgent()

