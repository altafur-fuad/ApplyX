"""
Planner Agent — generates a structured plan from a goal and profile.

Input: raw goal, structured profile, available tools.
Output: ordered plan, task dependencies, required tools, risk levels.

Phase 3: deterministic/mock planner. Real LLM integration comes later.
"""

from __future__ import annotations

import abc
import json
import logging
from typing import Any, Dict, List, Optional
from uuid import uuid4

from app.agents.models import (
    AgentPlan,
    AgentTask,
    AgentType,
    RiskLevel,
    TaskStatus,
)
from app.services.llm_service import get_llm_provider, LLMRequest, LLMMessage

logger = logging.getLogger(__name__)

class BasePlannerAgent(abc.ABC):
    @abc.abstractmethod
    async def create_plan(
        self,
        raw_goal: str,
        structured_constraints: Dict[str, Any],
        profile: Optional[Dict[str, Any]] = None,
        available_tools: Optional[List[str]] = None,
    ) -> AgentPlan:
        ...

class PlannerAgent(BasePlannerAgent):
    """Planner using structured output."""
    async def create_plan(
        self,
        raw_goal: str,
        structured_constraints: Dict[str, Any],
        profile: Optional[Dict[str, Any]] = None,
        available_tools: Optional[List[str]] = None,
    ) -> AgentPlan:
        provider = get_llm_provider()
        
        system_prompt = """You are the ApplyX Planner Agent.
Your job is to read the user's goal, constraints, and profile, and produce a strict JSON execution plan.
Do NOT invent skills, requirements, opportunities, or evidence.
Return insufficient evidence when source data is missing.
You must choose ONLY from registered tools.
You only PROPOSE tasks.
The plan should follow this canonical flow where appropriate: Research -> Eligibility -> Profile Fit -> Document -> Verification.
"""
        user_prompt = f"""
Goal: {raw_goal}
Constraints: {json.dumps(structured_constraints)}
Profile: {json.dumps(profile or {})}
Available Tools: {json.dumps(available_tools or [])}
"""
        request = LLMRequest(
            messages=[
                LLMMessage(role="system", content=system_prompt),
                LLMMessage(role="user", content=user_prompt)
            ],
            response_model=AgentPlan,
            temperature=0.0
        )
        
        response = await provider.complete(request)
        if response.parsed:
            return response.parsed
        else:
            try:
                data = json.loads(response.content)
                return AgentPlan(**data)
            except Exception as e:
                raise ValueError(f"Malformed planner output: {response.content}") from e


def get_planner_agent() -> BasePlannerAgent:
    return PlannerAgent()

