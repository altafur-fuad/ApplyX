"""
Tests for agent plan schema validation, task models, and state transitions.

Covers Parts D, E, K, L requirements.
"""

from __future__ import annotations

import pytest
from uuid import uuid4

from app.agents.models import (
    AgentEventType,
    AgentGuardrails,
    AgentPlan,
    AgentRunState,
    AgentTask,
    AgentType,
    ConfidenceLevel,
    Evidence,
    EvidenceStatus,
    RiskLevel,
    RunStatus,
    TaskStatus,
    TERMINAL_RUN_STATUSES,
    TERMINAL_TASK_STATUSES,
)
from app.agents.state import (
    InvalidStateTransition,
    transition_run,
    transition_task,
    VALID_RUN_TRANSITIONS,
    VALID_TASK_TRANSITIONS,
)


# ---------------------------------------------------------------------------
# 1. Agent plan schema validation
# ---------------------------------------------------------------------------

class TestAgentPlanValidation:
    """Test plan and task schema validation."""

    def test_valid_plan_creation(self):
        """A well-formed plan should parse without errors."""
        plan = AgentPlan(
            goal_summary="Find Flutter internships",
            constraints={"skills": ["flutter"], "remote": True},
            tasks=[
                AgentTask(
                    agent_type=AgentType.RESEARCH,
                    name="Search opportunities",
                    depends_on=[],
                    risk_level=RiskLevel.LOW,
                ),
            ],
        )
        assert plan.goal_summary == "Find Flutter internships"
        assert len(plan.tasks) == 1
        assert plan.tasks[0].status == TaskStatus.PENDING

    def test_task_defaults(self):
        """Task should have sane defaults."""
        task = AgentTask(
            agent_type=AgentType.RESEARCH,
            name="Test task",
        )
        assert task.status == TaskStatus.PENDING
        assert task.risk_level == RiskLevel.LOW
        assert task.requires_approval is False
        assert task.depends_on == []
        assert task.input == {}
        assert task.output is None

    def test_plan_get_ready_tasks(self):
        """get_ready_tasks should return tasks whose deps are completed."""
        t1 = AgentTask(id="t1", agent_type=AgentType.RESEARCH, name="T1")
        t2 = AgentTask(id="t2", agent_type=AgentType.ELIGIBILITY, name="T2", depends_on=["t1"])
        t3 = AgentTask(id="t3", agent_type=AgentType.PROFILE_FIT, name="T3", depends_on=["t2"])

        plan = AgentPlan(goal_summary="test", tasks=[t1, t2, t3])

        # Initially only t1 is ready
        ready = plan.get_ready_tasks()
        assert len(ready) == 1
        assert ready[0].id == "t1"

        # After t1 completes, t2 should be ready
        t1.status = TaskStatus.COMPLETED
        ready = plan.get_ready_tasks()
        assert len(ready) == 1
        assert ready[0].id == "t2"


# ---------------------------------------------------------------------------
# 2. Invalid task rejection
# ---------------------------------------------------------------------------

class TestInvalidTaskRejection:
    """Tasks with invalid data should be caught by validation."""

    def test_invalid_agent_type_rejected(self):
        """Invalid agent type should raise a validation error."""
        with pytest.raises(ValueError):
            AgentTask.model_validate({"agent_type": "nonexistent", "name": "bad task"})

    def test_invalid_risk_level_rejected(self):
        """Invalid risk level should raise a validation error."""
        with pytest.raises(ValueError):
            AgentTask.model_validate({
                "agent_type": AgentType.RESEARCH.value,
                "name": "bad risk",
                "risk_level": "extreme",
            })

    def test_invalid_task_status_rejected(self):
        """Invalid status should raise a validation error."""
        with pytest.raises(ValueError):
            AgentTask.model_validate({
                "agent_type": AgentType.RESEARCH.value,
                "name": "bad status",
                "status": "invalid_status",
            })


# ---------------------------------------------------------------------------
# 3. State transitions
# ---------------------------------------------------------------------------

class TestRunStateTransitions:
    """Test run state machine transitions."""

    def test_valid_run_transitions(self):
        """QUEUED → PLANNING → RUNNING → COMPLETED should succeed."""
        state = AgentRunState(goal_id="g1", user_id="u1")
        assert state.status == RunStatus.QUEUED

        transition_run(state, RunStatus.PLANNING)
        assert state.status == RunStatus.PLANNING
        assert state.started_at is not None

        transition_run(state, RunStatus.RUNNING)
        assert state.status == RunStatus.RUNNING

        transition_run(state, RunStatus.COMPLETED)
        assert state.status == RunStatus.COMPLETED
        assert state.completed_at is not None

    def test_invalid_run_transition_raises(self):
        """QUEUED → COMPLETED should raise InvalidStateTransition."""
        state = AgentRunState(goal_id="g1", user_id="u1")
        with pytest.raises(InvalidStateTransition):
            transition_run(state, RunStatus.COMPLETED)

    def test_terminal_run_state_cannot_transition(self):
        """Terminal states have no outgoing transitions."""
        for terminal in TERMINAL_RUN_STATUSES:
            state = AgentRunState(goal_id="g1", user_id="u1", status=terminal)
            for target in RunStatus:
                if target != terminal:
                    with pytest.raises(InvalidStateTransition):
                        transition_run(state, target)

    def test_queued_to_cancelled(self):
        """QUEUED → CANCELLED should succeed."""
        state = AgentRunState(goal_id="g1", user_id="u1")
        transition_run(state, RunStatus.CANCELLED)
        assert state.status == RunStatus.CANCELLED

    def test_running_to_waiting_for_approval(self):
        """RUNNING → WAITING_FOR_APPROVAL should succeed."""
        state = AgentRunState(goal_id="g1", user_id="u1", status=RunStatus.RUNNING)
        transition_run(state, RunStatus.WAITING_FOR_APPROVAL)
        assert state.status == RunStatus.WAITING_FOR_APPROVAL


class TestTaskStateTransitions:
    """Test task state machine transitions."""

    def test_valid_task_transitions(self):
        """PENDING → RUNNING → COMPLETED should succeed."""
        task = AgentTask(agent_type=AgentType.RESEARCH, name="test")
        transition_task(task, TaskStatus.RUNNING)
        assert task.status == TaskStatus.RUNNING
        assert task.started_at is not None

        transition_task(task, TaskStatus.COMPLETED)
        assert task.status == TaskStatus.COMPLETED
        assert task.completed_at is not None

    def test_invalid_task_transition_raises(self):
        """PENDING → COMPLETED should raise InvalidStateTransition."""
        task = AgentTask(agent_type=AgentType.RESEARCH, name="test")
        with pytest.raises(InvalidStateTransition):
            transition_task(task, TaskStatus.COMPLETED)

    def test_terminal_task_state_cannot_transition(self):
        """Terminal task states cannot transition."""
        for terminal in TERMINAL_TASK_STATUSES:
            task = AgentTask(
                agent_type=AgentType.RESEARCH,
                name="test",
                status=terminal,
            )
            for target in TaskStatus:
                if target != terminal:
                    with pytest.raises(InvalidStateTransition):
                        transition_task(task, target)


# ---------------------------------------------------------------------------
# 4. Evidence model
# ---------------------------------------------------------------------------

class TestEvidenceModel:
    """Test evidence and confidence models."""

    def test_evidence_creation(self):
        """Well-formed evidence should parse correctly."""
        ev = Evidence(
            claim="Remote work is allowed",
            status=EvidenceStatus.CONFIRMED,
            source_url="https://example.com/source",
            confidence=ConfidenceLevel.HIGH,
            evidence_type="opportunity_listing",
        )
        assert ev.claim == "Remote work is allowed"
        assert ev.status == EvidenceStatus.CONFIRMED
        assert ev.confidence == ConfidenceLevel.HIGH

    def test_evidence_defaults(self):
        """Evidence should have safe defaults."""
        ev = Evidence(claim="Some claim")
        assert ev.status == EvidenceStatus.UNCERTAIN
        assert ev.confidence == ConfidenceLevel.INSUFFICIENT
        assert ev.source_url is None

    def test_evidence_invalid_status(self):
        """Invalid evidence status should raise."""
        with pytest.raises(ValueError):
            Evidence.model_validate({"claim": "bad", "status": "totally_true"})


# ---------------------------------------------------------------------------
# 5. Guardrails
# ---------------------------------------------------------------------------

class TestGuardrails:
    """Test guardrail limit defaults."""

    def test_default_guardrails(self):
        g = AgentGuardrails()
        assert g.max_tasks_per_run == 25
        assert g.max_tool_calls_per_run == 50
        assert g.max_retries_per_task == 2
        assert g.run_timeout_minutes == 10

    def test_custom_guardrails(self):
        g = AgentGuardrails(max_tasks_per_run=5, max_tool_calls_per_run=10)
        assert g.max_tasks_per_run == 5
        assert g.max_tool_calls_per_run == 10
