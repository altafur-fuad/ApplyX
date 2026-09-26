"""
Planner Agent — generates a structured plan from a goal and profile.

Input: raw goal, structured profile, available tools.
Output: ordered plan, task dependencies, required tools, risk levels.

Phase 3: deterministic/mock planner. Real LLM integration comes later.
"""

from __future__ import annotations

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

logger = logging.getLogger(__name__)


class PlannerAgent:
    """
    Deterministic planner for Phase 3.

    Produces a canonical plan based on the goal's structured_constraints.
    The real LLM-backed planner will use the same output contract.
    """

    def create_plan(
        self,
        raw_goal: str,
        structured_constraints: Dict[str, Any],
        profile: Optional[Dict[str, Any]] = None,
        available_tools: Optional[List[str]] = None,
    ) -> AgentPlan:
        """
        Generate a deterministic plan.

        The plan always follows the canonical flow:
        Research → Eligibility → Profile Fit → Document → Verification
        """
        goal_summary = raw_goal[:200] if raw_goal else "Unspecified goal"
        constraints = dict(structured_constraints) if structured_constraints else {}

        # Build ordered tasks
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
            "plan_created goal_summary=%s task_count=%d",
            goal_summary[:50],
            len(tasks),
        )
        return plan
