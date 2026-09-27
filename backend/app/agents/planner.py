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

class MockPlanner(BasePlannerAgent):
    """
    Deterministic planner for Phase 3 and tests.
    Produces a canonical plan based on the goal's structured_constraints.
    """
    async def create_plan(
        self,
        raw_goal: str,
        structured_constraints: Dict[str, Any],
        profile: Optional[Dict[str, Any]] = None,
        available_tools: Optional[List[str]] = None,
    ) -> AgentPlan:
        goal_summary = raw_goal[:200] if raw_goal else "Unspecified goal"
        constraints = dict(structured_constraints) if structured_constraints else {}

        t1_id = str(uuid4())
        t2_id = str(uuid4())
        t3_id = str(uuid4())
        t4_id = str(uuid4())
        t5_id = str(uuid4())

        tasks = [
            AgentTask(
                id=t1_id,
                agent_type=AgentType.RESEARCH,
                name="Research opportunities",
                status=TaskStatus.PENDING,
                input={"constraints": constraints},
                depends_on=[],
                risk_level=RiskLevel.LOW,
                requires_approval=False,
            ),
            AgentTask(
                id=t2_id,
                agent_type=AgentType.ELIGIBILITY,
                name="Analyze eligibility",
                status=TaskStatus.PENDING,
                input={},
                depends_on=[t1_id],
                risk_level=RiskLevel.LOW,
                requires_approval=False,
            ),
            AgentTask(
                id=t3_id,
                agent_type=AgentType.PROFILE_FIT,
                name="Evaluate profile fit",
                status=TaskStatus.PENDING,
                input={},
                depends_on=[t2_id],
                risk_level=RiskLevel.LOW,
                requires_approval=False,
            ),
            AgentTask(
                id=t4_id,
                agent_type=AgentType.DOCUMENT,
                name="Prepare application documents",
                status=TaskStatus.PENDING,
                input={},
                depends_on=[t3_id],
                risk_level=RiskLevel.MEDIUM,
                requires_approval=False,
            ),
            AgentTask(
                id=t5_id,
                agent_type=AgentType.VERIFICATION,
                name="Verify results",
                status=TaskStatus.PENDING,
                input={},
                depends_on=[t4_id],
                risk_level=RiskLevel.LOW,
                requires_approval=False,
            ),
        ]

        plan = AgentPlan(
            goal_summary=goal_summary,
            constraints=constraints,
            tasks=tasks,
        )

        logger.info(
            "mock_plan_created goal_summary=%s task_count=%d",
            goal_summary[:50],
            len(tasks),
        )
        return plan


class RealLLMPlanner(BasePlannerAgent):
    """Real LLM Planner using structured output."""
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
    from app.core.config import get_settings
    settings = get_settings()
    if settings.openai_api_key:
        return RealLLMPlanner()
    return MockPlanner()

