"""
Tests for Phase 7B - Cancellation, Timeout, and Task Retry.
"""

from unittest.mock import patch, MagicMock
from uuid import uuid4
import pytest

from app.agents.models import RunStatus, TaskStatus
from app.agents.orchestrator import Orchestrator
from app.core.errors import APIError

class TestCancellationAndTimeout:
    @pytest.mark.asyncio
    @patch("app.services.agent_run_service.get_agent_run")
    async def test_cancellation_detection(self, mock_get_run):
        # Setup mock to return CANCELLED after a certain point.
        # Actually, if we mock it to always return CANCELLED, it should cancel on the first iteration.
        mock_get_run.return_value = {"status": RunStatus.CANCELLED.value}
        
        orch = Orchestrator()
        run_id = str(uuid4())
        
        state = await orch.run(
            goal_data={"id": str(uuid4()), "raw_goal": "Find software engineering internship"},
            profile_data={"skills": ["python"]},
            run_id=run_id,
            user_id="user123"
        )
        
        assert state.status == RunStatus.CANCELLED
        assert state.error == "Run was cancelled by user."

    @pytest.mark.asyncio
    async def test_global_timeout(self):
        orch = Orchestrator()
        orch.guardrails.run_timeout_minutes = 0 # Immediate timeout
        
        run_id = str(uuid4())
        state = await orch.run(
            goal_data={"id": str(uuid4()), "raw_goal": "Find software engineering internship"},
            profile_data={"skills": ["python"]},
            run_id=run_id,
            user_id="user123"
        )
        
        assert state.status == RunStatus.FAILED
        assert state.error is not None and "timeout exceeded" in state.error


class TestTaskRetry:
    @pytest.mark.asyncio
    async def test_transient_failure_retry(self):
        orch = Orchestrator()
        run_id = str(uuid4())
        
        # Patch _dispatch_task to fail on first attempt, then succeed
        call_count = 0
        original_dispatch = orch._dispatch_task
        
        async def mock_dispatch(state, task, context):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                # Throw a transient error (not in the exclusion list)
                raise Exception("Transient network failure")
            return await original_dispatch(state, task, context)
            
        with patch.object(orch, "_dispatch_task", new=mock_dispatch):
            state = await orch.run(
                goal_data={"id": str(uuid4()), "raw_goal": "Find software engineering internship"},
                profile_data={"skills": ["python"]},
                run_id=run_id
            )
            
        # Run should complete and have 1 retry
        assert state.status == RunStatus.COMPLETED
        assert state.total_retries == 1

    @pytest.mark.asyncio
    async def test_non_retryable_failure(self):
        orch = Orchestrator()
        run_id = str(uuid4())
        
        # Patch _dispatch_task to fail with non-retryable error
        async def mock_dispatch_fail(state, task, context):
            from app.tools.registry import ToolPermissionDenied
            raise ToolPermissionDenied("Blocked by policy")
            
        with patch.object(orch, "_dispatch_task", new=mock_dispatch_fail):
            state = await orch.run(
                goal_data={"id": str(uuid4()), "raw_goal": "Find software engineering internship"},
                profile_data={"skills": ["python"]},
                run_id=run_id
            )
            
        # Run should fail immediately with 0 retries
        assert state.status == RunStatus.FAILED
        assert state.total_retries == 0
        assert state.error is not None and "Blocked by policy" in state.error
