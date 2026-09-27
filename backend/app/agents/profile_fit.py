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

class ProfileFitResultModel(BaseModel):
    opportunity_title: str
    fit_reasons: List[str]
    gaps: List[str]
    overall_fit: str

class ProfileFitListModel(BaseModel):
    fit_analyses: List[ProfileFitResultModel]

class ProfileFitAgent(BaseProfileFitAgent):
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
    return ProfileFitAgent()

