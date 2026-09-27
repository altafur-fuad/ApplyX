"""
Action Agent — prepares and executes approved external actions.

Enforces approval requirement. Executes only approved actions.
Phase 3: deterministic mock that prepares action payloads but
does not execute external submissions.
"""

from __future__ import annotations

import logging
from typing import Any, Dict

from app.agents.models import RiskLevel
from app.core.policies import ApprovalRequired, ActionBlocked, check_action_policy

logger = logging.getLogger(__name__)


class ActionAgent:
    """
    Deterministic action agent for Phase 3.

    Prepares action payloads and enforces approval policy.
    Never bypasses the policy gate.
    """

    def prepare_action(
        self,
        action_type: str,
        target: Dict[str, Any],
        risk_level: RiskLevel = RiskLevel.HIGH,
    ) -> Dict[str, Any]:
        """
        Prepare an action payload (but do not execute in Phase 3).

        Returns the prepared payload with approval requirements.
        """
        requires_approval = risk_level in (RiskLevel.HIGH, RiskLevel.CRITICAL)

        payload = {
            "action_type": action_type,
            "target": target,
            "risk_level": risk_level.value,
            "requires_approval": requires_approval,
            "status": "pending_approval" if requires_approval else "ready",
        }

        logger.info(
            "action_prepared type=%s risk=%s requires_approval=%s",
            action_type,
            risk_level.value,
            requires_approval,
        )

        return payload

    def execute_action(
        self,
        payload: Dict[str, Any],
        *,
        approval_granted: bool = False,
        user_id: str = "",
    ) -> Dict[str, Any]:
        """
        Execute a prepared action after policy check.

        In Phase 3, this is a dry-run that returns success without
        performing any external side effects.
        """
        risk_level = RiskLevel(payload.get("risk_level", "high"))

        # Policy gate — may raise ApprovalRequired or ActionBlocked
        check_action_policy(
            risk_level,
            approval_granted=approval_granted,
            user_id=user_id,
        )

        # Phase 3: dry-run execution
        result = {
            "action_type": payload.get("action_type"),
            "status": "executed_dry_run",
            "risk_level": risk_level.value,
            "message": "Action executed (dry-run mode in Phase 3).",
        }

        logger.info(
            "action_executed type=%s status=dry_run user_id=%s",
            payload.get("action_type"),
            user_id[:8] + "…" if len(user_id) > 8 else "***",
        )

        return result
