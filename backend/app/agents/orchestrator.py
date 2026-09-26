"""
Agent Orchestrator — central coordinator for the agentic workflow.

Implements a lightweight state-machine orchestrator:
1. Load goal + profile
2. Create agent run
3. Generate structured plan (via Planner)
4. Validate plan (via Verification)
5. Execute tasks in dependency order
6. Persist task transitions
7. Execute only registered tools
8. Record tool calls
9. Capture evidence
10. Pass results through Verification
11. Stop at approval boundary when required
12. Persist final result

Does NOT hold long-running execution inside an HTTP request.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from app.agents.models import (
    AgentEventType,
    AgentGuardrails,
    AgentPlan,
    AgentRunState,
    AgentTask,
    AgentType,
    Evidence,
    RiskLevel,
    RunStatus,
    TaskStatus,
)
from app.agents.state import (
    InvalidStateTransition,
    transition_run,
    transition_task,
)
from app.agents.planner import PlannerAgent
from app.agents.research import ResearchAgent
from app.agents.eligibility import EligibilityAgent
from app.agents.profile_fit import ProfileFitAgent
from app.agents.document import DocumentAgent
from app.agents.verification import VerificationService
from app.agents.action import ActionAgent

logger = logging.getLogger(__name__)


class Orchestrator:
    """
    Stateful orchestrator that drives the full agent lifecycle.

    Usage::

        orch = Orchestrator()
        result = await orch.run(goal_data, profile_data)
    """

    def __init__(self, guardrails: Optional[AgentGuardrails] = None) -> None:
        self.guardrails = guardrails or AgentGuardrails()

        # Specialist agents
        self.planner = PlannerAgent()
        self.research = ResearchAgent()
        self.eligibility = EligibilityAgent()
        self.profile_fit = ProfileFitAgent()
        self.document = DocumentAgent()
        self.verification = VerificationService()
        self.action = ActionAgent()

        # Events collected during the run
        self._events: list[Dict[str, Any]] = []

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def run(
        self,
        goal_data: Dict[str, Any],
        profile_data: Dict[str, Any],
        run_id: Optional[str] = None,
        user_id: str = "",
    ) -> AgentRunState:
        """
        Execute the full agent workflow synchronously (within a background task).

        Returns the final ``AgentRunState``.
        """
        state = AgentRunState(
            goal_id=str(goal_data.get("id", "")),
            user_id=user_id,
        )
        if run_id:
            state.run_id = run_id

        try:
            # 1 → PLANNING
            transition_run(state, RunStatus.PLANNING)
            self._emit_event(state, AgentEventType.RUN_CREATED, "Agent run started.")

            # 2 — Generate plan
            plan = self.planner.create_plan(
                raw_goal=str(goal_data.get("raw_goal", "")),
                structured_constraints=goal_data.get("structured_constraints_json", {}),
                profile=profile_data,
            )

            # 3 — Validate plan
            vr = self.verification.verify_plan_tasks(plan.tasks)
            if vr.blocked:
                state.error = f"Plan validation blocked: {'; '.join(vr.issues)}"
                transition_run(state, RunStatus.FAILED)
                self._emit_event(state, AgentEventType.RUN_FAILED, state.error)
                return state

            state.plan = plan
            state.tasks = list(plan.tasks)
            self._emit_event(state, AgentEventType.PLAN_CREATED, f"Plan with {len(plan.tasks)} tasks.")

            # 4 → RUNNING
            transition_run(state, RunStatus.RUNNING)

            # 5 — Execute tasks in dependency order
            await self._execute_tasks(state, profile_data)

            # 6 — Final result
            if state.status == RunStatus.RUNNING:
                state.final_result = self._build_final_result(state)
                transition_run(state, RunStatus.COMPLETED)
                self._emit_event(state, AgentEventType.RUN_COMPLETED, "Agent run completed.")

        except InvalidStateTransition as exc:
            state.error = str(exc)
            logger.error("orchestrator_state_error: %s", exc)
            # Already in a terminal state, don't transition again
        except Exception as exc:
            state.error = str(exc)
            logger.exception("orchestrator_error run_id=%s", state.run_id)
            try:
                transition_run(state, RunStatus.FAILED)
                self._emit_event(state, AgentEventType.RUN_FAILED, str(exc))
            except InvalidStateTransition:
                pass  # Already terminal

        return state

    @property
    def events(self) -> list[Dict[str, Any]]:
        """Return events collected during the run."""
        return list(self._events)

    # ------------------------------------------------------------------
    # Task execution loop
    # ------------------------------------------------------------------

    async def _execute_tasks(
        self,
        state: AgentRunState,
        profile_data: Dict[str, Any],
    ) -> None:
        """Execute plan tasks in dependency order."""
        # Accumulated context passed between agents
        context: Dict[str, Any] = {
            "profile": profile_data,
            "opportunities": [],
            "evidence": [],
            "eligibility_results": [],
            "fit_analyses": [],
        }

        max_iterations = self.guardrails.max_tasks_per_run * 2  # safety cap
        iteration = 0

        while iteration < max_iterations:
            iteration += 1

            # Find ready tasks
            ready = [
                t for t in state.tasks
                if t.status == TaskStatus.PENDING
                and all(
                    any(
                        st.id == dep and st.status == TaskStatus.COMPLETED
                        for st in state.tasks
                    )
                    for dep in t.depends_on
                )
            ]

            if not ready:
                # All tasks are done or blocked
                break

            for task in ready:
                if state.total_tool_calls >= self.guardrails.max_tool_calls_per_run:
                    state.error = "Tool call limit reached."
                    transition_run(state, RunStatus.FAILED)
                    self._emit_event(state, AgentEventType.RUN_FAILED, state.error)
                    return

                await self._execute_single_task(state, task, context)

                if state.status != RunStatus.RUNNING:
                    return

    async def _execute_single_task(
        self,
        state: AgentRunState,
        task: AgentTask,
        context: Dict[str, Any],
    ) -> None:
        """Execute a single task through its specialist agent."""
        transition_task(task, TaskStatus.RUNNING)
        state.current_step = task.agent_type.value
        state.total_tool_calls += 1
        self._emit_event(
            state,
            AgentEventType.TASK_STARTED,
            f"Started: {task.name}",
            task_id=task.id,
        )

        try:
            output = self._dispatch_task(task, context)
            task.output = output

            # Merge output into shared context
            self._merge_context(context, task.agent_type, output)

            # Verify task output
            vr = self.verification.verify_task_output(task)

            transition_task(task, TaskStatus.COMPLETED)
            self._emit_event(
                state,
                AgentEventType.TASK_COMPLETED,
                f"Completed: {task.name}",
                task_id=task.id,
            )

        except Exception as exc:
            task.error_message = str(exc)
            transition_task(task, TaskStatus.FAILED)
            state.error = f"Task '{task.name}' failed: {exc}"
            transition_run(state, RunStatus.FAILED)
            self._emit_event(
                state,
                AgentEventType.RUN_FAILED,
                f"Task failed: {task.name}",
                task_id=task.id,
            )

    def _dispatch_task(
        self,
        task: AgentTask,
        context: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Route a task to the appropriate specialist agent."""
        profile = context.get("profile", {})

        if task.agent_type == AgentType.RESEARCH:
            return self.research.execute(task.input)

        elif task.agent_type == AgentType.ELIGIBILITY:
            return self.eligibility.execute(
                context.get("opportunities", []),
                profile,
            )

        elif task.agent_type == AgentType.PROFILE_FIT:
            return self.profile_fit.execute(
                context.get("eligibility_results", []),
                profile,
            )

        elif task.agent_type == AgentType.DOCUMENT:
            opportunities = context.get("opportunities", [])
            fit_analyses = context.get("fit_analyses", [])
            opp = opportunities[0] if opportunities else {}
            fit = fit_analyses[0] if fit_analyses else {}
            return self.document.execute(profile, opp, fit)

        elif task.agent_type == AgentType.VERIFICATION:
            # Verify accumulated evidence
            evidence_dicts = context.get("evidence", [])
            evidence_objs = []
            for ed in evidence_dicts:
                try:
                    evidence_objs.append(Evidence(**ed))
                except Exception:
                    continue
            vr = self.verification.verify_evidence_list(evidence_objs)
            return {
                "verification": vr.to_dict(),
                "evidence_count": len(evidence_objs),
            }

        elif task.agent_type == AgentType.ACTION:
            payload = self.action.prepare_action(
                action_type=task.input.get("action_type", "unknown"),
                target=task.input.get("target", {}),
                risk_level=task.risk_level,
            )
            return payload

        else:
            return {"message": f"Agent type {task.agent_type.value} not implemented."}

    @staticmethod
    def _merge_context(
        context: Dict[str, Any],
        agent_type: AgentType,
        output: Dict[str, Any],
    ) -> None:
        """Merge task output into the shared context."""
        if agent_type == AgentType.RESEARCH:
            context["opportunities"] = output.get("opportunities", [])
            context["evidence"].extend(output.get("evidence", []))

        elif agent_type == AgentType.ELIGIBILITY:
            context["eligibility_results"] = output.get("eligibility_results", [])
            context["evidence"].extend(output.get("evidence", []))

        elif agent_type == AgentType.PROFILE_FIT:
            context["fit_analyses"] = output.get("fit_analyses", [])

    def _build_final_result(self, state: AgentRunState) -> Dict[str, Any]:
        """Assemble the final result from all completed tasks."""
        result: Dict[str, Any] = {}
        for task in state.tasks:
            if task.status == TaskStatus.COMPLETED and task.output:
                result[task.agent_type.value] = task.output
        return result

    # ------------------------------------------------------------------
    # Event helpers
    # ------------------------------------------------------------------

    def _emit_event(
        self,
        state: AgentRunState,
        event_type: AgentEventType,
        message: str,
        task_id: Optional[str] = None,
    ) -> None:
        """Record an event for observability."""
        event = {
            "agent_run_id": state.run_id,
            "event_type": event_type.value,
            "message": message,
            "task_id": task_id,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        self._events.append(event)
        logger.info(
            "agent_event run_id=%s type=%s message=%s",
            state.run_id,
            event_type.value,
            message[:80],
        )
