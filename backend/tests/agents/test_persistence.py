"""
Tests for Phase 7A - Agent Task and Tool Call Persistence.
"""

from unittest.mock import patch, MagicMock
from uuid import uuid4
import pytest
import json

from app.agents.models import RunStatus, TaskStatus, RiskLevel
from app.agents.orchestrator import Orchestrator
from app.tools.registry import ToolRegistry, BaseTool
from app.tools.models import ToolDefinition, ToolResult

# ---------------------------------------------------------
# Mock Tool for testing Tool Call persistence
# ---------------------------------------------------------
class DummyTool(BaseTool):
    def __init__(self, should_fail=False):
        self.should_fail = should_fail
        self.definition = ToolDefinition(
            name="dummy_tool",
            description="Does nothing",
            input_schema={}
        )

    @property
    def risk_level(self) -> RiskLevel:
        return RiskLevel.LOW

    async def execute(self, input_data: dict) -> ToolResult:
        if self.should_fail:
            return ToolResult(success=False, error="Dummy failure")
        return ToolResult(success=True, data={"dummy": "success"})


class TestTaskPersistence:
    @pytest.mark.asyncio
    @patch("app.services.agent_task_service.create_agent_task")
    @patch("app.services.agent_task_service.update_agent_task")
    async def test_tasks_persisted_during_run(self, mock_update, mock_create):
        # We want to ensure create_agent_task is called for each planned task
        # and update_agent_task is called on start, complete, or fail.
        orch = Orchestrator()
        run_id = str(uuid4())
        
        state = await orch.run(
            goal_data={"id": str(uuid4()), "raw_goal": "Find software engineering internship"},
            profile_data={"skills": ["python"]},
            run_id=run_id
        )
        
        # 5 tasks are created by the mock planner
        assert mock_create.call_count == 5
        
        # Verify first call to create_agent_task
        first_call = mock_create.call_args_list[0]
        kwargs = first_call.kwargs
        assert kwargs["agent_run_id"] == run_id
        assert kwargs["status"] == TaskStatus.PENDING.value
        assert "task_id" in kwargs
        assert "agent_type" in kwargs
        
        # Tasks update status to RUNNING and COMPLETED
        # For 5 tasks, that is at least 10 updates
        assert mock_update.call_count >= 10
        
        # Verify an update call
        running_updates = [call for call in mock_update.call_args_list if call.args[1].get("status") == TaskStatus.RUNNING.value]
        completed_updates = [call for call in mock_update.call_args_list if call.args[1].get("status") == TaskStatus.COMPLETED.value]
        
        assert len(running_updates) == 5
        assert len(completed_updates) == 5
        
        # Completed update should have output_json
        assert "output_json" in completed_updates[0].args[1]
        assert "completed_at" in completed_updates[0].args[1]

class TestToolCallPersistence:
    @pytest.mark.asyncio
    @patch("app.services.tool_call_service.create_tool_call")
    @patch("app.services.tool_call_service.update_tool_call")
    async def test_tool_calls_persisted_during_execution(self, mock_update, mock_create):
        registry = ToolRegistry()
        registry.register(DummyTool())
        
        run_id = str(uuid4())
        task_id = str(uuid4())
        
        mock_create.return_value = {"id": "mock-tool-call-id"}
        
        # Execute tool with agent_run_id and task_id
        await registry.execute(
            tool_name="dummy_tool",
            input_data={"foo": "bar"},
            agent_run_id=run_id,
            task_id=task_id
        )
        
        # Verify create
        mock_create.assert_called_once_with(
            agent_run_id=run_id,
            tool_name="dummy_tool",
            risk_level=RiskLevel.LOW.value,
            task_id=task_id,
            input_json={"foo": "bar"}
        )
        
        # Verify update
        mock_update.assert_called_once()
        args, kwargs = mock_update.call_args
        assert args[0] == "mock-tool-call-id"
        assert args[1]["status"] == "completed"
        assert args[1]["output_json"] == {"dummy": "success"}

    @pytest.mark.asyncio
    @patch("app.services.tool_call_service.create_tool_call")
    @patch("app.services.tool_call_service.update_tool_call")
    async def test_tool_call_failed_persistence(self, mock_update, mock_create):
        registry = ToolRegistry()
        registry.register(DummyTool(should_fail=True))
        
        run_id = str(uuid4())
        
        mock_create.return_value = {"id": "mock-tool-call-fail"}
        
        # Execute failing tool
        await registry.execute(
            tool_name="dummy_tool",
            input_data={},
            agent_run_id=run_id
        )
        
        mock_update.assert_called_once()
        args, kwargs = mock_update.call_args
        assert args[1]["status"] == "failed"
