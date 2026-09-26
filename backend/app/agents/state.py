"""
Agent state management — helpers for run / task state transitions.

All transitions are validated: invalid state changes are rejected.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from app.agents.models import (
    AgentRunState,
    AgentTask,
    RunStatus,
    TaskStatus,
    TERMINAL_RUN_STATUSES,
    TERMINAL_TASK_STATUSES,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Valid state transitions
# ---------------------------------------------------------------------------

VALID_RUN_TRANSITIONS: dict[RunStatus, frozenset[RunStatus]] = {
    RunStatus.QUEUED: frozenset({RunStatus.PLANNING, RunStatus.CANCELLED, RunStatus.FAILED}),
    RunStatus.PLANNING: frozenset({RunStatus.RUNNING, RunStatus.FAILED, RunStatus.CANCELLED}),
    RunStatus.RUNNING: frozenset({
        RunStatus.WAITING_FOR_INPUT,
        RunStatus.WAITING_FOR_APPROVAL,
        RunStatus.COMPLETED,
        RunStatus.FAILED,
        RunStatus.CANCELLED,
    }),
    RunStatus.WAITING_FOR_INPUT: frozenset({RunStatus.RUNNING, RunStatus.CANCELLED, RunStatus.FAILED}),
    RunStatus.WAITING_FOR_APPROVAL: frozenset({RunStatus.RUNNING, RunStatus.CANCELLED, RunStatus.FAILED}),
    # Terminal states have no outgoing transitions.
    RunStatus.COMPLETED: frozenset(),
    RunStatus.FAILED: frozenset(),
    RunStatus.CANCELLED: frozenset(),
}

VALID_TASK_TRANSITIONS: dict[TaskStatus, frozenset[TaskStatus]] = {
    TaskStatus.PENDING: frozenset({TaskStatus.RUNNING, TaskStatus.CANCELLED}),
    TaskStatus.RUNNING: frozenset({
        TaskStatus.WAITING_FOR_INPUT,
        TaskStatus.WAITING_FOR_APPROVAL,
        TaskStatus.COMPLETED,
        TaskStatus.FAILED,
        TaskStatus.CANCELLED,
    }),
    TaskStatus.WAITING_FOR_INPUT: frozenset({TaskStatus.RUNNING, TaskStatus.CANCELLED, TaskStatus.FAILED}),
    TaskStatus.WAITING_FOR_APPROVAL: frozenset({TaskStatus.RUNNING, TaskStatus.CANCELLED, TaskStatus.FAILED}),
    TaskStatus.COMPLETED: frozenset(),
    TaskStatus.FAILED: frozenset(),
    TaskStatus.CANCELLED: frozenset(),
}


# ---------------------------------------------------------------------------
# Transition helpers
# ---------------------------------------------------------------------------

class InvalidStateTransition(Exception):
    """Raised when a state transition is not allowed."""
    pass


def transition_run(state: AgentRunState, new_status: RunStatus) -> AgentRunState:
    """
    Attempt to move *state* to *new_status*, raising on illegal transitions.
    Mutates and returns the same state object for convenience.
    """
    allowed = VALID_RUN_TRANSITIONS.get(state.status, frozenset())
    if new_status not in allowed:
        raise InvalidStateTransition(
            f"Run {state.run_id}: cannot transition from {state.status.value} to {new_status.value}"
        )

    state.status = new_status
    now = datetime.now(timezone.utc)

    if new_status == RunStatus.PLANNING:
        state.started_at = state.started_at or now
    elif new_status in TERMINAL_RUN_STATUSES:
        state.completed_at = now

    logger.info(
        "run_state_transition run_id=%s new_status=%s",
        state.run_id,
        new_status.value,
    )
    return state


def transition_task(task: AgentTask, new_status: TaskStatus) -> AgentTask:
    """
    Attempt to move *task* to *new_status*, raising on illegal transitions.
    """
    allowed = VALID_TASK_TRANSITIONS.get(task.status, frozenset())
    if new_status not in allowed:
        raise InvalidStateTransition(
            f"Task {task.id}: cannot transition from {task.status.value} to {new_status.value}"
        )

    task.status = new_status
    now = datetime.now(timezone.utc)

    if new_status == TaskStatus.RUNNING:
        task.started_at = task.started_at or now
    elif new_status in TERMINAL_TASK_STATUSES:
        task.completed_at = now

    logger.info(
        "task_state_transition task_id=%s new_status=%s",
        task.id,
        new_status.value,
    )
    return task
