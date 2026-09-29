import pytest
from unittest.mock import patch, MagicMock
from uuid import uuid4
from datetime import datetime, timezone

from app.agents.models import RunStatus, TaskStatus, RiskLevel, AgentTask, AgentType, AgentRunState
from app.agents.orchestrator import Orchestrator
from app.core.policies import ApprovalRequired
from app.agents.state import transition_run, transition_task

@pytest.mark.asyncio
async def test_complete_two_step_approval_lifecycle():
    orch = Orchestrator()
    user_id = "test-user-123"
    run_id = str(uuid4())

    task1_id = str(uuid4())
    task2_action_id = str(uuid4())

    task1 = AgentTask(
        id=task1_id,
        agent_type=AgentType.RESEARCH,
        name="Research",
        status=TaskStatus.PENDING,
        input={},
        depends_on=[],
        risk_level=RiskLevel.LOW
    )

    action_task = AgentTask(
        id=task2_action_id,
        agent_type=AgentType.ACTION,
        name="Submit application",
        status=TaskStatus.PENDING,
        input={"action_type": "submit", "target": {}},
        depends_on=[task1_id],
        risk_level=RiskLevel.HIGH,
        requires_approval=True,
    )

    state = AgentRunState(
        run_id=run_id,
        user_id=user_id,
        goal_id=str(uuid4())
    )
    state.tasks = [task1, action_task]
    transition_run(state, RunStatus.PLANNING)
    transition_run(state, RunStatus.RUNNING)

    call_counts = {"research": 0, "action": 0}

    async def mock_dispatch(self, state, task, context):
        if task.agent_type == AgentType.RESEARCH:
            call_counts["research"] += 1
            return {"opportunities": ["opp1"]}
        elif task.agent_type == AgentType.ACTION:
            call_counts["action"] += 1
            raise ApprovalRequired("High-risk actions require explicit approval.")
        return {}

    with patch.object(Orchestrator, '_dispatch_task', new=mock_dispatch):
        with patch('app.services.agent_task_service.update_agent_task'), \
             patch('app.services.agent_run_service.get_agent_run', return_value={"status": "running"}), \
             patch('app.services.agent_event_service.create_agent_event'):
            await orch._execute_tasks(state, {}, datetime.now(timezone.utc), 600)

    assert state.status == RunStatus.WAITING_FOR_APPROVAL
    assert action_task.status == TaskStatus.WAITING_FOR_APPROVAL
    assert task1.status == TaskStatus.COMPLETED
    assert call_counts["research"] == 1
    assert call_counts["action"] == 1

    # SIMULATE API RESUME
    transition_run(state, RunStatus.RUNNING)
    
    async def mock_dispatch_resume(self, state, task, context_internal):
        if task.agent_type == AgentType.RESEARCH:
            call_counts["research"] += 1
            return {"opportunities": ["opp1"]}
        elif task.agent_type == AgentType.ACTION:
            call_counts["action"] += 1
            return {"status": "executed_dry_run"}
        return {}

    with patch.object(Orchestrator, '_dispatch_task', new=mock_dispatch_resume):
        with patch('app.services.agent_task_service.update_agent_task'), \
             patch('app.services.agent_run_service.get_agent_run', return_value={"status": "running"}), \
             patch('app.services.agent_event_service.create_agent_event'):
            # Resume the paused task directly
            await orch._execute_single_task(state, action_task, {})
            # Then continue the rest of the queue
            await orch._execute_tasks(state, {}, datetime.now(timezone.utc), 600)

    if state.status == RunStatus.RUNNING:
        state.final_result = orch._build_final_result(state)
        transition_run(state, RunStatus.COMPLETED)

    assert state.status == RunStatus.COMPLETED
    assert action_task.status == TaskStatus.COMPLETED
    assert call_counts["research"] == 1
    assert call_counts["action"] == 2
    assert state.final_result is not None
    assert state.final_result[AgentType.ACTION.value]["status"] == "executed_dry_run"

@pytest.mark.asyncio
async def test_cancelled_run_cannot_resume():
    orch = Orchestrator()
    state = AgentRunState(run_id=str(uuid4()), user_id="user1", goal_id="goal1")
    action_task = AgentTask(
        id=str(uuid4()), agent_type=AgentType.ACTION, name="Action", status=TaskStatus.WAITING_FOR_APPROVAL,
        input={}, depends_on=[], risk_level=RiskLevel.HIGH
    )
    state.tasks = [action_task]
    transition_run(state, RunStatus.PLANNING)
    transition_run(state, RunStatus.RUNNING)
    transition_run(state, RunStatus.WAITING_FOR_APPROVAL)

    # API user cancels
    transition_run(state, RunStatus.CANCELLED)

    # If someone attempts to resume, it should raise InvalidStateTransition
    with pytest.raises(Exception):
        transition_run(state, RunStatus.RUNNING)

@pytest.mark.asyncio
async def test_failed_run_cannot_resume():
    orch = Orchestrator()
    state = AgentRunState(run_id=str(uuid4()), user_id="user1", goal_id="goal1")
    action_task = AgentTask(
        id=str(uuid4()), agent_type=AgentType.ACTION, name="Action", status=TaskStatus.WAITING_FOR_APPROVAL,
        input={}, depends_on=[], risk_level=RiskLevel.HIGH
    )
    state.tasks = [action_task]
    transition_run(state, RunStatus.PLANNING)
    transition_run(state, RunStatus.RUNNING)
    transition_run(state, RunStatus.WAITING_FOR_APPROVAL)

    # Run fails due to timeout
    transition_run(state, RunStatus.FAILED)

    with pytest.raises(Exception):
        transition_run(state, RunStatus.RUNNING)
