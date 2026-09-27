"""
Tests for the Tool Registry and Policy Gate.
Covers Parts B and C of Phase 3 requirements.
"""

import pytest

from app.agents.models import RiskLevel
from app.core.policies import ActionBlocked, ApprovalRequired, check_action_policy
from app.tools.base import BaseTool
from app.tools.models import ToolDefinition, ToolResult
from app.tools.registry import ToolNotRegistered, ToolPermissionDenied, ToolRegistry


# Mock tools for testing
class LowRiskTool(BaseTool):
    definition = ToolDefinition(
        name="low_risk_tool",
        description="A low risk tool",
        risk_level=RiskLevel.LOW,
    )

    async def execute(self, input_data: dict) -> ToolResult:
        return ToolResult(success=True, data={"result": "low_ok"})


class MediumRiskTool(BaseTool):
    definition = ToolDefinition(
        name="medium_risk_tool",
        description="A medium risk tool",
        risk_level=RiskLevel.MEDIUM,
    )

    async def execute(self, input_data: dict) -> ToolResult:
        return ToolResult(success=True, data={"result": "medium_ok"})


class HighRiskTool(BaseTool):
    definition = ToolDefinition(
        name="high_risk_tool",
        description="A high risk tool",
        risk_level=RiskLevel.HIGH,
    )

    async def execute(self, input_data: dict) -> ToolResult:
        return ToolResult(success=True, data={"result": "high_ok"})


class CriticalRiskTool(BaseTool):
    definition = ToolDefinition(
        name="critical_risk_tool",
        description="A critical risk tool",
        risk_level=RiskLevel.CRITICAL,
    )

    async def execute(self, input_data: dict) -> ToolResult:
        return ToolResult(success=True, data={"result": "critical_ok"})


@pytest.fixture
def registry():
    r = ToolRegistry()
    r.register(LowRiskTool())
    r.register(MediumRiskTool())
    r.register(HighRiskTool())
    r.register(CriticalRiskTool())
    return r


class TestToolRegistry:
    def test_tool_registration(self, registry: ToolRegistry):
        """Tool should be registered."""
        assert registry.has("low_risk_tool")
        assert registry.has("high_risk_tool")

    @pytest.mark.asyncio
    async def test_unknown_tool_rejected(self, registry: ToolRegistry):
        """Unknown tool execution should raise."""
        with pytest.raises(ToolNotRegistered):
            await registry.execute("unknown_tool", {})

    @pytest.mark.asyncio
    async def test_low_tool_executes(self, registry: ToolRegistry):
        """LOW risk tool should execute automatically."""
        record = await registry.execute("low_risk_tool", {})
        assert record.status == "completed"
        assert record.output_data == {"result": "low_ok"}

    @pytest.mark.asyncio
    async def test_high_tool_blocked_without_approval(self, registry: ToolRegistry):
        """HIGH risk tool must block if no approval is given."""
        with pytest.raises(ToolPermissionDenied):
            await registry.execute("high_risk_tool", {}, approval_granted=False)

    @pytest.mark.asyncio
    async def test_high_tool_executes_with_approval(self, registry: ToolRegistry):
        """HIGH risk tool should execute with approval."""
        record = await registry.execute("high_risk_tool", {}, approval_granted=True)
        assert record.status == "completed"

    @pytest.mark.asyncio
    async def test_critical_blocked(self, registry: ToolRegistry):
        """CRITICAL tool must always be blocked."""
        with pytest.raises(ToolPermissionDenied):
            await registry.execute("critical_risk_tool", {}, approval_granted=True)


class TestPolicyGate:
    def test_low_policy(self):
        # Should not raise
        check_action_policy(RiskLevel.LOW)

    def test_medium_policy(self):
        # Should not raise
        check_action_policy(RiskLevel.MEDIUM)

    def test_high_approval_requirement(self):
        with pytest.raises(ApprovalRequired):
            check_action_policy(RiskLevel.HIGH, approval_granted=False)
        # With approval, should not raise
        check_action_policy(RiskLevel.HIGH, approval_granted=True)

    def test_critical_block(self):
        with pytest.raises(ActionBlocked):
            check_action_policy(RiskLevel.CRITICAL, approval_granted=True)
