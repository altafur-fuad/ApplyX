"""
Tool base class — abstract interface every tool must implement.
"""

from __future__ import annotations

import abc
from typing import Any, Dict

from app.tools.models import ToolDefinition, ToolResult


class BaseTool(abc.ABC):
    """
    Abstract base for all agent tools.

    Subclass this, set ``definition``, and implement ``execute``.
    The registry validates that every registered tool is a ``BaseTool``
    with a properly formed ``ToolDefinition``.
    """

    definition: ToolDefinition

    @abc.abstractmethod
    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        """
        Run the tool with the given *input_data* and return a ``ToolResult``.

        Implementations must be deterministic and testable for Phase 3.
        External I/O will be added in later phases behind feature flags.
        """
        ...

    @property
    def name(self) -> str:
        return self.definition.name

    @property
    def risk_level(self):
        return self.definition.risk_level

    @property
    def requires_approval(self) -> bool:
        return self.definition.requires_approval
