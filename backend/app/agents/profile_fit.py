"""
Profile-Fit Agent — compares opportunity requirements with profile evidence.

Explains matching and missing skills. Never invents experience.
Phase 3: deterministic mock implementation.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List

logger = logging.getLogger(__name__)


class ProfileFitAgent:
    """
    Deterministic profile fit analysis for Phase 3.
    """

    def execute(
        self,
        eligibility_results: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Generate fit reasons and gaps for each opportunity."""
        user_skills = set(
            s.lower()
            for s in (profile.get("skills") or profile.get("skills_json") or [])
        )
        user_headline = profile.get("headline", "")
        user_education = profile.get("education_level", "")

        fit_analyses = []

        for result in eligibility_results:
            met = result.get("met_requirements", [])
            missing = result.get("missing_requirements", [])

            fit_reasons = []
            if met:
                fit_reasons.append(
                    f"Profile matches requirements: {', '.join(met)}."
                )
            if user_headline:
                fit_reasons.append(f"Headline: {user_headline}")
            if user_education:
                fit_reasons.append(f"Education: {user_education}")

            gaps = []
            if missing:
                gaps.append(
                    f"Missing skills/requirements: {', '.join(missing)}."
                )

            fit_analyses.append({
                "opportunity_title": result.get("opportunity_title", ""),
                "fit_reasons": fit_reasons,
                "gaps": gaps,
                "overall_fit": "strong" if not missing else ("partial" if met else "weak"),
            })

        logger.info("profile_fit_complete count=%d", len(fit_analyses))

        return {"fit_analyses": fit_analyses}
