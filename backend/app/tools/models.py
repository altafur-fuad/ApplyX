"""
Tool data models — definitions and schemas for the tool system.
"""

from __future__ import annotations

from typing import Any, Dict, Optional, Type

from pydantic import BaseModel, Field

from app.agents.models import RiskLevel


class RetryPolicy(BaseModel):
    """Retry behaviour for a tool."""
    max_retries: int = 0
    retry_on_timeout: bool = True
    retry_on_failure: bool = False


class ToolDefinition(BaseModel):
    """
    Canonical tool definition per AGENT_SPEC §6.

    Every tool in the registry must have one of these.
    """
    name: str
    description: str
    input_schema: Dict[str, Any] = Field(default_factory=dict)
    output_schema: Dict[str, Any] = Field(default_factory=dict)
    risk_level: RiskLevel = RiskLevel.LOW
    requires_approval: bool = False
    timeout_seconds: int = 30
    retry_policy: RetryPolicy = Field(default_factory=RetryPolicy)
    idempotent: bool = True


class ToolCallRecord(BaseModel):
    """Record of a single tool invocation for observability."""
    tool_name: str
    input_data: Dict[str, Any] = Field(default_factory=dict)
    output_data: Optional[Dict[str, Any]] = None
    status: str = "started"
    risk_level: RiskLevel = RiskLevel.LOW
    duration_ms: Optional[float] = None
    error_message: Optional[str] = None


class ToolResult(BaseModel):
    """Standardised result from tool execution."""
    success: bool
    data: Dict[str, Any] = Field(default_factory=dict)
    error: Optional[str] = None
