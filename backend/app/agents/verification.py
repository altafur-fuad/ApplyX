"""
Verification service — validates agent outputs, evidence, and claims.

Responsibilities:
- Schema validity
- Evidence presence
- Unsupported-claim detection
- Confidence/uncertainty state enforcement
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from app.agents.models import (
    AgentTask,
    ConfidenceLevel,
    Evidence,
    EvidenceStatus,
    TaskStatus,
)

logger = logging.getLogger(__name__)


class VerificationResult:
    """Outcome of a verification pass."""

    def __init__(self) -> None:
        self.passed: bool = True
        self.issues: list[str] = []
        self.downgraded_claims: list[str] = []
        self.blocked: bool = False

    def add_issue(self, issue: str, *, block: bool = False) -> None:
        self.issues.append(issue)
        self.passed = False
        if block:
            self.blocked = True

    def add_downgrade(self, claim: str) -> None:
        self.downgraded_claims.append(claim)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "passed": self.passed,
            "blocked": self.blocked,
            "issues": self.issues,
            "downgraded_claims": self.downgraded_claims,
        }


class VerificationService:
    """
    Stateless verification layer.

    All methods are deterministic and testable.
    """

    def verify_task_output(self, task: AgentTask) -> VerificationResult:
        """Verify that a completed task has valid output."""
        result = VerificationResult()

        if task.status != TaskStatus.COMPLETED:
            result.add_issue(f"Task '{task.name}' is not completed (status={task.status.value}).")
            return result

        if task.output is None:
            result.add_issue(f"Task '{task.name}' completed without output.", block=True)
            return result

        # Output should be a dict
        if not isinstance(task.output, dict):
            result.add_issue(f"Task '{task.name}' output is not a dict.", block=True)

        return result

    def verify_evidence_list(self, evidence: List[Evidence]) -> VerificationResult:
        """Verify a list of evidence records for completeness."""
        result = VerificationResult()

        if not evidence:
            result.add_issue("No evidence provided.")
            return result

        for ev in evidence:
            if not ev.claim:
                result.add_issue("Evidence record has empty claim.")
                continue

            if ev.status == EvidenceStatus.INSUFFICIENT_EVIDENCE:
                result.add_downgrade(ev.claim)

            if ev.confidence == ConfidenceLevel.INSUFFICIENT and ev.status in (
                EvidenceStatus.CONFIRMED,
                EvidenceStatus.LIKELY,
            ):
                # Inconsistency: claim is "confirmed" but confidence is "insufficient"
                result.add_issue(
                    f"Claim '{ev.claim}' has inconsistent status/confidence."
                )

            # Check source presence for confirmed claims
            if ev.status == EvidenceStatus.CONFIRMED and not ev.source_url:
                result.add_downgrade(ev.claim)
                result.add_issue(
                    f"Confirmed claim '{ev.claim}' lacks source URL; downgraded."
                )

        return result

    def verify_plan_tasks(self, tasks: List[AgentTask]) -> VerificationResult:
        """Verify structural integrity of a plan's tasks."""
        result = VerificationResult()

        if not tasks:
            result.add_issue("Plan has no tasks.", block=True)
            return result

        task_ids = {t.id for t in tasks}

        for task in tasks:
            if not task.name:
                result.add_issue(f"Task {task.id} has no name.")

            for dep in task.depends_on:
                if dep not in task_ids:
                    result.add_issue(
                        f"Task '{task.name}' depends on unknown task '{dep}'.",
                        block=True,
                    )

        # Check for circular dependencies (simple DFS)
        if self._has_cycle(tasks):
            result.add_issue("Plan contains circular task dependencies.", block=True)

        return result

    @staticmethod
    def _has_cycle(tasks: List[AgentTask]) -> bool:
        """Return True if there is a dependency cycle among tasks."""
        adjacency: Dict[str, List[str]] = {t.id: list(t.depends_on) for t in tasks}
        visited: set[str] = set()
        in_stack: set[str] = set()

        def dfs(node: str) -> bool:
            if node in in_stack:
                return True
            if node in visited:
                return False
            visited.add(node)
            in_stack.add(node)
            for dep in adjacency.get(node, []):
                if dfs(dep):
                    return True
            in_stack.discard(node)
            return False

        for task_id in adjacency:
            if dfs(task_id):
                return True
        return False
