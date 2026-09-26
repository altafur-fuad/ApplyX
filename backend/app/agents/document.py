"""
Document Agent — drafts resumes, cover letters, and application answers.

Uses only user-provided or source-backed facts.
Phase 3: deterministic mock that creates template drafts.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List

logger = logging.getLogger(__name__)


class DocumentAgent:
    """
    Deterministic document agent for Phase 3.

    Creates template-based drafts using profile data.
    """

    def execute(
        self,
        profile: Dict[str, Any],
        opportunity: Dict[str, Any],
        fit_analysis: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Generate a draft cover letter from profile + opportunity data."""
        full_name = profile.get("full_name", "Applicant")
        headline = profile.get("headline", "")
        skills = profile.get("skills") or profile.get("skills_json") or []
        fit_reasons = fit_analysis.get("fit_reasons", [])

        opp_title = opportunity.get("title", "the opportunity")
        org = opportunity.get("organization", "the organization")

        content_lines = [
            f"Dear Hiring Team at {org},",
            "",
            f"I am writing to express my interest in {opp_title}.",
            "",
        ]

        if headline:
            content_lines.append(f"As {headline}, I bring relevant experience to this role.")
            content_lines.append("")

        if skills:
            content_lines.append(f"Key skills: {', '.join(skills[:5])}.")
            content_lines.append("")

        if fit_reasons:
            content_lines.append("Relevant qualifications:")
            for reason in fit_reasons[:3]:
                content_lines.append(f"  - {reason}")
            content_lines.append("")

        content_lines.extend([
            "I look forward to the opportunity to contribute.",
            "",
            f"Sincerely,",
            full_name,
        ])

        draft = {
            "kind": "cover_letter",
            "title": f"Cover Letter - {opp_title}",
            "content": "\n".join(content_lines),
            "is_draft": True,
            "version": 1,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        logger.info("document_draft_created kind=%s", draft["kind"])

        return {"documents": [draft]}
