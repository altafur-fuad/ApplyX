"""
Tool registry — central, server-side registry of all permitted tools.

Rules:
- Only registered tools may be executed.
- An LLM may never invent arbitrary tool names.
- Tool calls are logged.
- Risk policy is enforced before execution.
"""

from __future__ import annotations

import logging
import time
from typing import Any, Dict, Optional

from app.agents.models import RiskLevel
from app.tools.base import BaseTool
from app.tools.models import ToolCallRecord, ToolResult

logger = logging.getLogger(__name__)


class ToolNotRegistered(Exception):
    """Raised when a caller tries to invoke a tool that is not in the registry."""
    pass


class ToolPermissionDenied(Exception):
    """Raised when a tool call is blocked by the risk / approval policy."""
    pass


class ToolRegistry:
    """
    Singleton-style tool registry.

    Usage::

        registry = ToolRegistry()
        registry.register(MyTool())
        result = await registry.execute("my_tool", {...}, approval_granted=False)
    """

    def __init__(self) -> None:
        self._tools: Dict[str, BaseTool] = {}

    # ----- Registration -----

    def register(self, tool: BaseTool) -> None:
        """Register a tool instance. Raises on duplicate names."""
        name = tool.name
        if name in self._tools:
            raise ValueError(f"Tool '{name}' is already registered.")
        self._tools[name] = tool
        logger.info("tool_registered name=%s risk=%s", name, tool.risk_level.value)

    def get(self, name: str) -> Optional[BaseTool]:
        """Return the tool or ``None``."""
        return self._tools.get(name)

    def has(self, name: str) -> bool:
        return name in self._tools

    def list_tools(self) -> list[str]:
        """Return the names of all registered tools."""
        return list(self._tools.keys())

    def list_definitions(self):
        """Return ToolDefinitions for all registered tools."""
        return [t.definition for t in self._tools.values()]

    # ----- Execution -----

    async def execute(
        self,
        tool_name: str,
        input_data: Dict[str, Any],
        *,
        approval_granted: bool = False,
    ) -> ToolCallRecord:
        """
        Look up *tool_name*, enforce policy, execute, and return a
        ``ToolCallRecord`` for persistence/observability.
        """
        tool = self._tools.get(tool_name)
        if tool is None:
            raise ToolNotRegistered(f"Tool '{tool_name}' is not registered.")

        # --- Risk policy gate ---
        self._enforce_policy(tool, approval_granted=approval_granted)

        record = ToolCallRecord(
            tool_name=tool_name,
            input_data=input_data,
            risk_level=tool.risk_level,
        )

        start = time.monotonic()
        try:
            result: ToolResult = await tool.execute(input_data)
            elapsed = (time.monotonic() - start) * 1000

            record.status = "completed" if result.success else "failed"
            record.output_data = result.data
            record.duration_ms = elapsed
            if result.error:
                record.error_message = result.error

        except Exception as exc:
            elapsed = (time.monotonic() - start) * 1000
            record.status = "failed"
            record.error_message = str(exc)
            record.duration_ms = elapsed
            logger.exception(
                "tool_execution_error tool=%s duration_ms=%.2f",
                tool_name,
                elapsed,
            )

        logger.info(
            "tool_executed tool=%s status=%s duration_ms=%.2f risk=%s",
            tool_name,
            record.status,
            record.duration_ms or 0,
            record.risk_level.value,
        )
        return record

    # ----- Policy -----

    @staticmethod
    def _enforce_policy(tool: BaseTool, *, approval_granted: bool) -> None:
        """
        Apply the canonical risk policy from AGENT_SPEC §5.

        - LOW: execute automatically.
        - MEDIUM: execute (normal authenticated ownership check done by caller).
        - HIGH: requires explicit approval.
        - CRITICAL: blocked for MVP.
        """
        risk = tool.risk_level

        if risk == RiskLevel.CRITICAL:
            raise ToolPermissionDenied(
                f"Tool '{tool.name}' is classified as CRITICAL and is blocked in MVP."
            )

        if risk == RiskLevel.HIGH and not approval_granted:
            raise ToolPermissionDenied(
                f"Tool '{tool.name}' requires explicit approval (risk=HIGH)."
            )

        # LOW and MEDIUM pass through.


# ---------------------------------------------------------------------------
# Module-level singleton
# ---------------------------------------------------------------------------

_global_registry: Optional[ToolRegistry] = None


def get_tool_registry() -> ToolRegistry:
    """Return (and lazily create) the global tool registry."""
    global _global_registry
    if _global_registry is None:
        _global_registry = ToolRegistry()
        _register_builtins(_global_registry)
    return _global_registry


def _register_builtins(registry: ToolRegistry) -> None:
    """Register all Phase 3 built-in tools."""
    from app.tools.builtins import (
        CalculateMatchSignalsTool,
        NormalizeOpportunityTool,
        SummarizeEvidenceTool,
        CreateDraftArtifactTool,
        PersistAgentEventTool,
    )
    registry.register(CalculateMatchSignalsTool())
    registry.register(NormalizeOpportunityTool())
    registry.register(SummarizeEvidenceTool())
    registry.register(CreateDraftArtifactTool())
    registry.register(PersistAgentEventTool())
