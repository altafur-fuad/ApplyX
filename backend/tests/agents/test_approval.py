"""
Tests for Phase 7C — Approval boundary, policy enforcement, and pause/resume.
"""

import pytest
from unittest.mock import patch, MagicMock
from uuid import uuid4

from app.agents.models import RunStatus, TaskStatus, RiskLevel
from app.agents.orchestrator import Orchestrator
from app.core.policies import ApprovalRequired, ActionBlocked, check_action_policy
from app.agents.action import ActionAgent


class TestPolicyEnforcement:
    def test_critical_action_blocked(self):
        with pytest.raises(ActionBlocked, match="Critical actions are blocked"):
            check_action_policy(RiskLevel.CRITICAL, approval_granted=False)

    def test_critical_action_blocked_even_with_approval(self):
        with pytest.raises(ActionBlocked, match="Critical actions are blocked"):
            check_action_policy(RiskLevel.CRITICAL, approval_granted=True)

    def test_high_risk_requires_approval(self):
        with pytest.raises(ApprovalRequired):
            check_action_policy(RiskLevel.HIGH, approval_granted=False)

    def test_high_risk_passes_with_approval(self):
        # Should not raise
        check_action_policy(RiskLevel.HIGH, approval_granted=True)

    def test_medium_risk_passes_without_approval(self):
        check_action_policy(RiskLevel.MEDIUM, approval_granted=False)

    def test_low_risk_passes_without_approval(self):
        check_action_policy(RiskLevel.LOW, approval_granted=False)


class TestActionAgentApproval:
    def test_prepare_action_high_risk_requires_approval(self):
        agent = ActionAgent()
        payload = agent.prepare_action(
            action_type="submit_application",
            target={"org": "TestCo"},
            risk_level=RiskLevel.HIGH,
        )
        assert payload["requires_approval"] is True
        assert payload["status"] == "pending_approval"

    def test_prepare_action_low_risk_ready(self):
        agent = ActionAgent()
        payload = agent.prepare_action(
            action_type="save_draft",
            target={},
            risk_level=RiskLevel.LOW,
        )
        assert payload["requires_approval"] is False
        assert payload["status"] == "ready"

    def test_execute_action_blocked_without_approval(self):
        agent = ActionAgent()
        payload = {"action_type": "submit", "risk_level": "high"}
        with pytest.raises(ApprovalRequired):
            agent.execute_action(payload, approval_granted=False)

    def test_execute_action_critical_always_blocked(self):
        agent = ActionAgent()
        payload = {"action_type": "delete", "risk_level": "critical"}
        with pytest.raises(ActionBlocked):
            agent.execute_action(payload, approval_granted=True)

    def test_execute_action_succeeds_with_approval(self):
        agent = ActionAgent()
        payload = {"action_type": "submit", "risk_level": "high"}
        result = agent.execute_action(payload, approval_granted=True, user_id="user-123")
        assert result["status"] == "executed_dry_run"


class TestApprovalServiceGuards:
    @patch("app.services.approval_service.get_supabase_client")
    def test_reject_non_pending_approval(self, mock_get_client):
        """Cannot approve/reject an already-resolved approval."""
        mock_client = MagicMock()
        mock_get_client.return_value = mock_client

        mock_table = MagicMock()
        mock_client.table.return_value = mock_table
        mock_query = MagicMock()
        mock_table.select.return_value = mock_query
        mock_eq1 = MagicMock()
        mock_query.eq.return_value = mock_eq1
        mock_eq2 = MagicMock()
        mock_eq1.eq.return_value = mock_eq2

        # Return an already-approved record
        mock_res = MagicMock()
        mock_res.data = [{"status": "approved"}]
        mock_eq2.execute.return_value = mock_res

        from app.services.approval_service import approve
        from app.core.errors import APIError

        with pytest.raises(APIError) as exc_info:
            approve("user-123", "approval-id")
        assert exc_info.value.status_code == 422


class TestOrchestratorApprovalPause:
    @pytest.mark.asyncio
    async def test_approval_required_pauses_run(self):
        """When ActionAgent raises ApprovalRequired, the run pauses."""
        orch = Orchestrator()

        async def mock_dispatch(state, task, context):
            if task.agent_type.value == "action":
                raise ApprovalRequired("High-risk actions require explicit approval.")
            return await Orchestrator._dispatch_task(orch, state, task, context)

        with patch.object(orch, "_dispatch_task", new=mock_dispatch):
            # Force a plan that includes an action task
            from app.agents.models import AgentPlan, AgentTask, AgentType
            import uuid

            action_task = AgentTask(
                id=str(uuid.uuid4()),
                agent_type=AgentType.ACTION,
                name="Submit application",
                status=TaskStatus.PENDING,
                input={"action_type": "submit", "target": {}},
                depends_on=[],
                risk_level=RiskLevel.HIGH,
                requires_approval=True,
            )

            # Mock the planner to return a single action task
            async def mock_plan(*args, **kwargs):
                return AgentPlan(
                    goal_summary="Submit",
                    constraints={},
                    tasks=[action_task],
                )

            with patch.object(orch.planner, "create_plan", new=mock_plan):
                state = await orch.run(
                    goal_data={"id": str(uuid.uuid4()), "raw_goal": "Submit application"},
                    profile_data={"skills": ["python"]},
                    run_id=str(uuid.uuid4()),
                )

        assert state.status == RunStatus.WAITING_FOR_APPROVAL
