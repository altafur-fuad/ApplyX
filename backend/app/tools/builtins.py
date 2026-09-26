"""
Built-in safe tools — Phase 3 deterministic, testable tools.

These tools are read-only / workspace-only and do NOT connect to
uncontrolled external websites.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from typing import Any, Dict, List

from app.agents.models import ConfidenceLevel, Evidence, EvidenceStatus, RiskLevel
from app.tools.base import BaseTool
from app.tools.models import RetryPolicy, ToolDefinition, ToolResult


# ---------------------------------------------------------------------------
# 1. calculate_match_signals
# ---------------------------------------------------------------------------

class CalculateMatchSignalsTool(BaseTool):
    """
    Compare a user profile against an opportunity's requirements and return
    matching / missing signals.
    """

    definition = ToolDefinition(
        name="calculate_match_signals",
        description="Compare user skills/profile against opportunity requirements and return match signals.",
        input_schema={
            "type": "object",
            "properties": {
                "user_skills": {"type": "array", "items": {"type": "string"}},
                "requirements": {"type": "array", "items": {"type": "string"}},
                "user_location": {"type": "string"},
                "opportunity_location": {"type": "string"},
                "remote_status": {"type": "string"},
            },
            "required": ["user_skills", "requirements"],
        },
        output_schema={
            "type": "object",
            "properties": {
                "matched_skills": {"type": "array"},
                "missing_skills": {"type": "array"},
                "match_ratio": {"type": "number"},
                "location_match": {"type": "boolean"},
            },
        },
        risk_level=RiskLevel.LOW,
        requires_approval=False,
        timeout_seconds=5,
        retry_policy=RetryPolicy(max_retries=0),
        idempotent=True,
    )

    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        user_skills_raw: List[str] = input_data.get("user_skills", [])
        requirements_raw: List[str] = input_data.get("requirements", [])

        user_skills = {s.strip().lower() for s in user_skills_raw}
        requirements = {r.strip().lower() for r in requirements_raw}

        matched = user_skills & requirements
        missing = requirements - user_skills
        ratio = len(matched) / max(len(requirements), 1)

        # Location matching
        user_loc = (input_data.get("user_location") or "").lower()
        opp_loc = (input_data.get("opportunity_location") or "").lower()
        remote = (input_data.get("remote_status") or "").lower()
        location_match = (
            remote in ("remote", "hybrid")
            or (user_loc and opp_loc and user_loc in opp_loc)
        )

        return ToolResult(
            success=True,
            data={
                "matched_skills": sorted(matched),
                "missing_skills": sorted(missing),
                "match_ratio": round(ratio, 3),
                "location_match": location_match,
            },
        )


# ---------------------------------------------------------------------------
# 2. normalize_opportunity
# ---------------------------------------------------------------------------

class NormalizeOpportunityTool(BaseTool):
    """Normalize raw opportunity data into a canonical schema."""

    definition = ToolDefinition(
        name="normalize_opportunity",
        description="Normalize raw opportunity data into the canonical ApplyX schema.",
        input_schema={
            "type": "object",
            "properties": {
                "raw_data": {"type": "object"},
            },
            "required": ["raw_data"],
        },
        output_schema={"type": "object"},
        risk_level=RiskLevel.LOW,
        requires_approval=False,
        timeout_seconds=5,
        retry_policy=RetryPolicy(max_retries=0),
        idempotent=True,
    )

    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        raw = input_data.get("raw_data", {})

        title = str(raw.get("title", "")).strip()
        if not title:
            return ToolResult(success=False, error="Missing required field: title")

        content_str = json.dumps(raw, sort_keys=True)
        content_hash = hashlib.sha256(content_str.encode()).hexdigest()[:16]

        normalized = {
            "title": title,
            "organization": str(raw.get("organization", raw.get("company", ""))).strip(),
            "type": str(raw.get("type", raw.get("opportunity_type", ""))).strip().lower(),
            "location": str(raw.get("location", "")).strip(),
            "remote_status": str(raw.get("remote_status", raw.get("remote", ""))).strip().lower(),
            "description": str(raw.get("description", "")).strip(),
            "requirements": raw.get("requirements", raw.get("requirements_json", [])),
            "compensation_text": str(raw.get("compensation_text", raw.get("compensation", ""))).strip(),
            "source_url": str(raw.get("source_url", raw.get("url", ""))).strip(),
            "source_name": str(raw.get("source_name", raw.get("source", "unknown"))).strip(),
            "content_hash": content_hash,
        }

        return ToolResult(success=True, data=normalized)


# ---------------------------------------------------------------------------
# 3. summarize_evidence
# ---------------------------------------------------------------------------

class SummarizeEvidenceTool(BaseTool):
    """Aggregate a list of evidence records into a summary with confidence."""

    definition = ToolDefinition(
        name="summarize_evidence",
        description="Aggregate evidence records and produce a summary with overall confidence.",
        input_schema={
            "type": "object",
            "properties": {
                "evidence": {
                    "type": "array",
                    "items": {"type": "object"},
                },
            },
            "required": ["evidence"],
        },
        output_schema={"type": "object"},
        risk_level=RiskLevel.LOW,
        requires_approval=False,
        timeout_seconds=5,
        retry_policy=RetryPolicy(max_retries=0),
        idempotent=True,
    )

    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        raw_evidence: List[Dict[str, Any]] = input_data.get("evidence", [])

        parsed: list[Evidence] = []
        for item in raw_evidence:
            try:
                parsed.append(Evidence(**item))
            except Exception:
                # Skip malformed evidence entries rather than crash.
                continue

        if not parsed:
            return ToolResult(
                success=True,
                data={
                    "summary": "No evidence available.",
                    "total": 0,
                    "confidence": ConfidenceLevel.INSUFFICIENT.value,
                    "supported_claims": [],
                    "unsupported_claims": [],
                },
            )

        supported = [
            e for e in parsed
            if e.status in (EvidenceStatus.CONFIRMED, EvidenceStatus.LIKELY)
        ]
        unsupported = [
            e for e in parsed
            if e.status in (EvidenceStatus.UNCERTAIN, EvidenceStatus.INSUFFICIENT_EVIDENCE)
        ]

        # Overall confidence heuristic
        if len(supported) >= len(parsed) * 0.8:
            overall = ConfidenceLevel.HIGH
        elif len(supported) >= len(parsed) * 0.5:
            overall = ConfidenceLevel.MEDIUM
        elif supported:
            overall = ConfidenceLevel.LOW
        else:
            overall = ConfidenceLevel.INSUFFICIENT

        return ToolResult(
            success=True,
            data={
                "summary": f"{len(supported)} of {len(parsed)} claims are supported.",
                "total": len(parsed),
                "confidence": overall.value,
                "supported_claims": [e.claim for e in supported],
                "unsupported_claims": [e.claim for e in unsupported],
            },
        )


# ---------------------------------------------------------------------------
# 4. create_draft_artifact
# ---------------------------------------------------------------------------

class CreateDraftArtifactTool(BaseTool):
    """Create a draft document artifact (resume / cover letter / etc.)."""

    definition = ToolDefinition(
        name="create_draft_artifact",
        description="Create a draft document artifact using user-provided profile data.",
        input_schema={
            "type": "object",
            "properties": {
                "kind": {"type": "string", "enum": ["resume", "cover_letter", "short_answer", "portfolio_summary", "other"]},
                "title": {"type": "string"},
                "content": {"type": "string"},
                "application_id": {"type": "string"},
            },
            "required": ["kind", "title", "content"],
        },
        output_schema={"type": "object"},
        risk_level=RiskLevel.MEDIUM,
        requires_approval=False,
        timeout_seconds=10,
        retry_policy=RetryPolicy(max_retries=0),
        idempotent=True,
    )

    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        kind = input_data.get("kind", "other")
        title = input_data.get("title", "")
        content = input_data.get("content", "")

        if not title or not content:
            return ToolResult(success=False, error="title and content are required.")

        # In Phase 3 we return the artifact data without persisting to Supabase.
        # Persistence will be added when the Document service is wired up.
        artifact = {
            "kind": kind,
            "title": title,
            "content": content,
            "is_draft": True,
            "version": 1,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        return ToolResult(success=True, data=artifact)


# ---------------------------------------------------------------------------
# 5. persist_agent_event
# ---------------------------------------------------------------------------

class PersistAgentEventTool(BaseTool):
    """Record an agent event for the activity timeline."""

    definition = ToolDefinition(
        name="persist_agent_event",
        description="Record an agent event for observability and the user-facing timeline.",
        input_schema={
            "type": "object",
            "properties": {
                "agent_run_id": {"type": "string"},
                "event_type": {"type": "string"},
                "message": {"type": "string"},
                "payload": {"type": "object"},
            },
            "required": ["agent_run_id", "event_type"],
        },
        output_schema={"type": "object"},
        risk_level=RiskLevel.LOW,
        requires_approval=False,
        timeout_seconds=5,
        retry_policy=RetryPolicy(max_retries=1, retry_on_failure=True),
        idempotent=True,
    )

    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        # In Phase 3, we return the event data. The persistence service
        # (agent_event_service) will handle actual DB writes when wired.
        event = {
            "agent_run_id": input_data.get("agent_run_id"),
            "event_type": input_data.get("event_type"),
            "message": input_data.get("message"),
            "payload": input_data.get("payload", {}),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        return ToolResult(success=True, data=event)
