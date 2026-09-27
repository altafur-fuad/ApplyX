"""
Approval & risk policies — the final policy gate for risky actions.

Per folder-structure.md: backend/app/core/policies.py is the final
policy gate for risky actions.

Rules (AGENT_SPEC §5):
- LOW   → may execute automatically.
- MEDIUM → may execute with normal authenticated ownership.
- HIGH   → requires pending approval.
- CRITICAL → blocked for MVP.
"""

from __future__ import annotations

import logging
from typing import Optional

from app.agents.models import RiskLevel

logger = logging.getLogger(__name__)


class ApprovalRequired(Exception):
    """Raised when an action requires approval that has not been granted."""
    pass


class ActionBlocked(Exception):
    """Raised when an action is blocked entirely (CRITICAL risk in MVP)."""
    pass


def check_action_policy(
    risk_level: RiskLevel,
    *,
    approval_granted: bool = False,
    user_id: Optional[str] = None,
) -> None:
    """
    Evaluate whether an action at the given *risk_level* may proceed.

    Raises:
        ActionBlocked: if risk is CRITICAL.
        ApprovalRequired: if risk is HIGH and no approval.
    """
    if risk_level == RiskLevel.CRITICAL:
        logger.warning(
            "action_blocked risk=critical user_id=%s",
            _safe_user_id(user_id),
        )
        raise ActionBlocked("Critical actions are blocked in MVP.")

    if risk_level == RiskLevel.HIGH and not approval_granted:
        logger.info(
            "approval_required risk=high user_id=%s",
            _safe_user_id(user_id),
        )
        raise ApprovalRequired("High-risk actions require explicit approval.")

    # LOW / MEDIUM pass through.
    logger.debug(
        "action_permitted risk=%s user_id=%s",
        risk_level.value,
        _safe_user_id(user_id),
    )


def _safe_user_id(user_id: Optional[str]) -> str:
    """Return a privacy-safe representation of user_id for logs."""
    if not user_id:
        return "unknown"
    if len(user_id) > 8:
        return user_id[:4] + "…" + user_id[-4:]
    return "***"
