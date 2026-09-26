"""
Tests for Verification layer and Planner Agent.
Covers Parts D and E.
"""

from app.agents.models import (
    AgentTask,
    AgentType,
    ConfidenceLevel,
    Evidence,
    EvidenceStatus,
    TaskStatus,
)
from app.agents.planner import PlannerAgent
from app.agents.verification import VerificationService


class TestVerification:
    def test_supported_evidence_passes(self):
        ver = VerificationService()
        ev = [
            Evidence(
                claim="Test claim",
                status=EvidenceStatus.CONFIRMED,
                source_url="http://test.com",
                confidence=ConfidenceLevel.HIGH,
            )
        ]
        result = ver.verify_evidence_list(ev)
        assert result.passed is True
        assert len(result.issues) == 0

    def test_unsupported_claim_downgraded(self):
        ver = VerificationService()
        ev = [
            Evidence(
                claim="Test claim",
                status=EvidenceStatus.CONFIRMED,
                source_url=None,  # missing source
                confidence=ConfidenceLevel.HIGH,
            )
        ]
        result = ver.verify_evidence_list(ev)
        assert result.passed is False
        assert "Test claim" in result.downgraded_claims

    def test_malformed_output_rejected(self):
        ver = VerificationService()
        task = AgentTask(
            agent_type=AgentType.RESEARCH,
            name="test task",
            status=TaskStatus.COMPLETED,
            output=None,
        )
        result = ver.verify_task_output(task)
        assert result.passed is False
        assert result.blocked is True


class TestPlanner:
    def test_deterministic_plan_generation(self):
        planner = PlannerAgent()
        plan = planner.create_plan(
            raw_goal="Find me an internship",
            structured_constraints={"skills": ["python"]},
        )
        assert len(plan.tasks) == 5
        assert plan.tasks[0].agent_type == AgentType.RESEARCH
        assert plan.tasks[1].agent_type == AgentType.ELIGIBILITY
        assert plan.tasks[2].agent_type == AgentType.PROFILE_FIT
        assert plan.tasks[3].agent_type == AgentType.DOCUMENT
        assert plan.tasks[4].agent_type == AgentType.VERIFICATION

    def test_dependency_ordering(self):
        planner = PlannerAgent()
        plan = planner.create_plan(
            raw_goal="Find me an internship",
            structured_constraints={"skills": ["python"]},
        )
        t1, t2, t3, t4, t5 = plan.tasks
        # Check that dependencies form a valid sequence
        assert t1.id in t2.depends_on
        assert t2.id in t3.depends_on
        assert t3.id in t4.depends_on
        assert t4.id in t5.depends_on
