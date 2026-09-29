"""
Agent models — Enums and Pydantic schemas for the agent runtime.

These models define the canonical state machine, task shapes, evidence,
and plan structures used across the entire agent system.
"""

from __future__ import annotations

import enum
from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class RunStatus(str, enum.Enum):
    """Agent run lifecycle states."""
    QUEUED = "queued"
    PLANNING = "planning"
    RUNNING = "running"
    WAITING_FOR_INPUT = "waiting_for_input"
    WAITING_FOR_APPROVAL = "waiting_for_approval"
    FAILED = "failed"
    CANCELLED = "cancelled"
    COMPLETED = "completed"


# Terminal states — once a run enters one of these it cannot transition further.
TERMINAL_RUN_STATUSES = frozenset({
    RunStatus.COMPLETED,
    RunStatus.FAILED,
    RunStatus.CANCELLED,
})


class TaskStatus(str, enum.Enum):
    """Agent task lifecycle states."""
    PENDING = "pending"
    RUNNING = "running"
    WAITING_FOR_INPUT = "waiting_for_input"
    WAITING_FOR_APPROVAL = "waiting_for_approval"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


TERMINAL_TASK_STATUSES = frozenset({
    TaskStatus.COMPLETED,
    TaskStatus.FAILED,
    TaskStatus.CANCELLED,
})


class AgentType(str, enum.Enum):
    """Specialist agent roles."""
    PLANNER = "planner"
    RESEARCH = "research"
    ELIGIBILITY = "eligibility"
    PROFILE_FIT = "profile_fit"
    DOCUMENT = "document"
    VERIFICATION = "verification"
    ACTION = "action"


class RiskLevel(str, enum.Enum):
    """Tool / action risk classification."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class ToolCallStatus(str, enum.Enum):
    """Status of a single tool invocation."""
    STARTED = "started"
    COMPLETED = "completed"
    FAILED = "failed"
    TIMED_OUT = "timed_out"


class EvidenceStatus(str, enum.Enum):
    """Confidence for an evidence-backed claim."""
    CONFIRMED = "confirmed"
    LIKELY = "likely"
    UNCERTAIN = "uncertain"
    INSUFFICIENT_EVIDENCE = "insufficient_evidence"


class ConfidenceLevel(str, enum.Enum):
    """Confidence rating for agent claims."""
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INSUFFICIENT = "insufficient"


class AgentEventType(str, enum.Enum):
    """Recommended event types for the mobile activity timeline."""
    RUN_CREATED = "run_created"
    PLAN_CREATED = "plan_created"
    PLANNING_STARTED = "planning_started"
    PLANNING_COMPLETED = "planning_completed"
    RESEARCH_STARTED = "research_started"
    RESEARCH_COMPLETED = "research_completed"
    NORMALIZATION_COMPLETED = "normalization_completed"
    DEDUPLICATION_COMPLETED = "deduplication_completed"
    ELIGIBILITY_COMPLETED = "eligibility_completed"
    PROFILE_FIT_COMPLETED = "profile_fit_completed"
    TASK_STARTED = "task_started"
    TASK_COMPLETED = "task_completed"
    TOOL_CALLED = "tool_called"
    SOURCE_FOUND = "source_found"
    ANALYSIS_COMPLETED = "analysis_completed"
    ARTIFACT_CREATED = "artifact_created"
    VERIFICATION_COMPLETED = "verification_completed"
    QUALITY_GATE_PASSED = "quality_gate_passed"
    QUALITY_GATE_FAILED = "quality_gate_failed"
    APPROVAL_REQUESTED = "approval_requested"
    APPROVAL_REQUIRED = "approval_required"
    APPROVAL_APPROVED = "approval_approved"
    APPROVAL_REJECTED = "approval_rejected"
    ACTION_STARTED = "action_started"
    ACTION_COMPLETED = "action_completed"
    RUN_FAILED = "run_failed"
    RUN_CANCELLED = "run_cancelled"
    RUN_COMPLETED = "run_completed"

class ErrorCategory(str, enum.Enum):
    """Robust error taxonomy for agent failures."""
    VALIDATION_ERROR = "validation_error"
    PROVIDER_CONFIGURATION_ERROR = "provider_configuration_error"
    PROVIDER_AUTHENTICATION_ERROR = "provider_authentication_error"
    QUOTA_ERROR = "quota_error"
    PROVIDER_TIMEOUT = "provider_timeout"
    PROVIDER_UNAVAILABLE = "provider_unavailable"
    SEARCH_FAILURE = "search_failure"
    MALFORMED_MODEL_OUTPUT = "malformed_model_output"
    TOOL_FAILURE = "tool_failure"
    POLICY_VIOLATION = "policy_violation"
    APPROVAL_REQUIRED = "approval_required"
    CANCELLATION = "cancellation"
    PERSISTENCE_FAILURE = "persistence_failure"
    INTERNAL_FAILURE = "internal_failure"

class EvidenceCoverage(str, enum.Enum):
    """Representation of evidence coverage for important claims."""
    SUPPORTED = "supported"
    PARTIALLY_SUPPORTED = "partially_supported"
    UNSUPPORTED = "unsupported"


# ---------------------------------------------------------------------------
# Evidence / Observation models
# ---------------------------------------------------------------------------

class Evidence(BaseModel):
    """A single evidence record backing a factual claim."""
    claim: str
    status: EvidenceStatus = EvidenceStatus.UNCERTAIN
    source_url: Optional[str] = None
    retrieved_at: Optional[datetime] = None
    confidence: ConfidenceLevel = ConfidenceLevel.INSUFFICIENT
    evidence_type: Optional[str] = None


# ---------------------------------------------------------------------------
# Task models
# ---------------------------------------------------------------------------

class AgentTask(BaseModel):
    """
    A single task in an agent plan.

    Matches the canonical task schema from AGENT_SPEC §4.
    """
    id: str = Field(default_factory=lambda: str(uuid4()))
    agent_type: AgentType
    name: str
    status: TaskStatus = TaskStatus.PENDING
    input: Dict[str, Any] = Field(default_factory=dict)
    output: Optional[Dict[str, Any]] = None
    depends_on: List[str] = Field(default_factory=list)
    risk_level: RiskLevel = RiskLevel.LOW
    requires_approval: bool = False
    error_message: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


# ---------------------------------------------------------------------------
# Plan models
# ---------------------------------------------------------------------------

class AgentPlan(BaseModel):
    """Structured planning output from the Planner agent."""
    goal_summary: str
    constraints: Dict[str, Any] = Field(default_factory=dict)
    tasks: List[AgentTask] = Field(default_factory=list)

    def get_ready_tasks(self) -> List[AgentTask]:
        """Return tasks whose dependencies are all completed."""
        completed_ids = {t.id for t in self.tasks if t.status == TaskStatus.COMPLETED}
        return [
            t for t in self.tasks
            if t.status == TaskStatus.PENDING
            and all(dep in completed_ids for dep in t.depends_on)
        ]


# ---------------------------------------------------------------------------
# Agent Run State (in-memory representation, persisted to DB)
# ---------------------------------------------------------------------------

class AgentRunState(BaseModel):
    """
    Full in-memory snapshot of an agent run.

    Every important state transition is persisted to the agent_runs / agent_tasks
    tables. This model is the in-process working copy.
    """
    run_id: str = Field(default_factory=lambda: str(uuid4()))
    goal_id: str
    user_id: str
    status: RunStatus = RunStatus.QUEUED
    current_step: Optional[str] = None
    plan: Optional[AgentPlan] = None
    tasks: List[AgentTask] = Field(default_factory=list)
    observations: List[Evidence] = Field(default_factory=list)
    final_result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    # Guardrail counters
    total_tool_calls: int = 0
    total_retries: int = 0


# ---------------------------------------------------------------------------
# Guardrail limits
# ---------------------------------------------------------------------------

class AgentGuardrails(BaseModel):
    """Development-default guardrail limits per AGENT_SPEC §10."""
    max_tasks_per_run: int = 25
    max_tool_calls_per_run: int = 50
    max_retries_per_task: int = 2
    run_timeout_minutes: int = 10


# ---------------------------------------------------------------------------
# API request / response schemas
# ---------------------------------------------------------------------------

class AgentRunCreateRequest(BaseModel):
    """POST /v1/agent-runs request body."""
    goal_id: UUID
    mode: str = "research_and_match"


class AgentRunResponse(BaseModel):
    """GET /v1/agent-runs/{run_id} response."""
    id: UUID
    goal_id: UUID
    user_id: UUID
    status: RunStatus
    current_step: Optional[str] = None
    progress: Optional[int] = None
    plan: Optional[Dict[str, Any]] = None
    final_summary: Optional[str] = None
    error: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class AgentEventResponse(BaseModel):
    """Single event in the events timeline."""
    id: UUID
    event_type: str
    message: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)
    task_id: Optional[UUID] = None
    created_at: datetime


class AgentEventsListResponse(BaseModel):
    """GET /v1/agent-runs/{run_id}/events response."""
    events: List[AgentEventResponse]
