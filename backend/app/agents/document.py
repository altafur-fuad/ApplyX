"""
Document Agent — drafts resumes, cover letters, and application answers.

Uses only user-provided or source-backed facts.
Phase 3: deterministic mock that creates template drafts.
"""

from __future__ import annotations

import logging
import json
from typing import Any, Dict
from app.agents.models import DocumentGenerationResult
from app.services.llm.factory import get_llm_provider
from app.services.llm.models import LLMRequest, LLMMessage
from app.services.document_service import save_generated_document

logger = logging.getLogger(__name__)

class DocumentAgent:
    """
    Document Agent for Phase 7D-A.
    Generates draft application artifacts using an LLM.
    Ensures fact safety and saves documents securely.
    """

    async def execute(
        self,
        profile: Dict[str, Any],
        opportunity: Dict[str, Any],
        fit_analysis: Dict[str, Any],
        user_id: str,
        task_input: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Generate a draft document using LLM."""
        provider = get_llm_provider()

        kind = task_input.get("document_kind", "cover_letter")
        instruction = task_input.get("instruction", "Generate a draft document.")
        application_id = task_input.get("application_id", "")

        if kind in ("resume", "resume_bullets"):
            kind_instructions = "Generate concise, role/opportunity-specific resume bullets. Focus on skills and project-oriented achievements from the profile. Ensure all claims are directly backed by the provided facts."
        elif kind == "cover_letter":
            kind_instructions = "Generate a structured cover letter draft. Include an opening, relevant background aligned to the opportunity, evidence/examples from the profile, and a closing. Do not overstate fit or eligibility."
        elif kind == "short_answer":
            kind_instructions = f"Generate a short-answer response to the following question or prompt: '{instruction}'. Maintain the question context."
        else:
            kind_instructions = f"Generate a structured draft based on: {instruction}"

        system_prompt = f"""You are the ApplyX Document Agent.
Your job is to generate a structured '{kind}' draft for the user based ONLY on their profile and the opportunity facts.
DO NOT invent, fabricate, or hallucinate qualifications, projects, experience, deadlines, achievements, company facts, or organization details.
Use ONLY the provided profile facts, fit analysis, and opportunity details.

{kind_instructions}

If required information is missing to fulfill the instruction, do not fabricate it. Include an uncertainty_warning in the generated section or output warnings.
Always produce a draft.
Return output adhering to the DocumentGenerationResult schema.
"""
        user_prompt = f"""
Opportunity: {json.dumps(opportunity)}
Profile: {json.dumps(profile)}
Fit Analysis (Evidence/Match): {json.dumps(fit_analysis)}
Instruction: {instruction}
"""

        request = LLMRequest(
            messages=[
                LLMMessage(role="system", content=system_prompt),
                LLMMessage(role="user", content=user_prompt)
            ],
            response_model=DocumentGenerationResult,
            temperature=0.2
        )

        response = await provider.complete(request)

        if response.parsed:
            result: DocumentGenerationResult = response.parsed
        else:
            try:
                data = json.loads(response.content)
                result = DocumentGenerationResult(**data)
            except Exception as e:
                raise ValueError(f"Malformed document LLM output: {response.content}") from e

        # Compile the document text from sections
        content_lines = []
        for section in result.generated_sections:
            if section.title:
                content_lines.append(f"## {section.title}")
            content_lines.append(section.content)
            if section.uncertainty_warnings:
                content_lines.append(f"*(Warning: {section.uncertainty_warnings})*")
            content_lines.append("")

        full_content = "\n".join(content_lines).strip()

        # Save or update in database
        saved_doc = None
        if user_id and application_id:
            try:
                saved_doc = save_generated_document(
                    user_id=user_id,
                    application_id=str(application_id),
                    kind=result.kind,
                    title=result.title,
                    content=full_content
                )
            except Exception as e:
                logger.error(f"Failed to persist generated document: {e}")

        logger.info(f"document_draft_generated kind={result.kind} user_id={user_id}")

        return {
            "document_result": result.model_dump(),
            "saved_document": saved_doc
        }
