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
    matching_skills: List[str]
    matching_interests: List[str]
    matching_experience: List[str]
    matching_education: List[str]
    matching_location: List[str]
    missing_information: List[str]
    uncertainty: List[str]
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
Output the specific matching skills, matching interests, matching experience, matching education, and matching location/remote preference.
Explicitly list any missing information or uncertainty in the profile or opportunity data.
Never invent experience, skills, or arbitrary numerical matching scores.
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

