"""
Research Agent — searches approved sources and collects opportunity records.

Phase 3: deterministic mock that returns sample opportunity data.
"""

from __future__ import annotations

import abc
import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict

from app.agents.models import Evidence, EvidenceStatus, ConfidenceLevel
from app.services.llm_service import get_llm_provider, LLMRequest, LLMMessage
from app.tools.registry import get_tool_registry
from app.services.opportunity.pipeline import process_search_results
from app.services.search.models import SearchResult

logger = logging.getLogger(__name__)


class BaseResearchAgent(abc.ABC):
    @abc.abstractmethod
    async def execute(self, input_data: Dict[str, Any], agent_run_id: str | None = None, task_id: str | None = None) -> Dict[str, Any]:
        ...

class ResearchAgent(BaseResearchAgent):
    async def execute(self, input_data: Dict[str, Any], agent_run_id: str | None = None, task_id: str | None = None) -> Dict[str, Any]:
        provider = get_llm_provider()
        registry = get_tool_registry()
        
        system_prompt = """You are the ApplyX Research Agent.
Your goal is to find relevant opportunities. You have access to the search_opportunities tool.
Formulate a search query based on the constraints provided, and call the search_opportunities tool.
Do NOT invent opportunities or evidence.
"""
        user_prompt = f"Constraints: {json.dumps(input_data.get('constraints', {}))}"
        
        from app.services.llm.models import LLMTool
        search_tool = registry.get("search_opportunities")
        tools_list = []
        if search_tool:
            tools_list.append(LLMTool(
                name=search_tool.definition.name,
                description=search_tool.definition.description,
                input_schema=search_tool.definition.input_schema
            ))
        
        request = LLMRequest(
            messages=[
                LLMMessage(role="system", content=system_prompt),
                LLMMessage(role="user", content=user_prompt)
            ],
            tools=tools_list,
            temperature=0.0
        )
        
        response = await provider.complete(request)
        
        raw_opportunities = []
        sources = set()
        
        if response.tool_calls:
            for tc in response.tool_calls:
                if tc.name in ("web_search", "search_opportunities"):
                    try:
                        args = json.loads(tc.arguments)
                    except:
                        args = {}
                    
                    record = await registry.execute("search_opportunities", args, agent_run_id=agent_run_id, task_id=task_id)
                    if record.status == "completed" and record.output_data:
                        results = record.output_data.get("results", [])

                        # Convert dicts back to SearchResult models
                        for r_dict in results:
                            # Safely handle retrieved_at string to datetime conversion if needed
                            raw_opportunities.append(SearchResult(**r_dict))

                        sources.update([r.get("source_name", "search_opportunities") for r in results])

        # Pipeline: Normalization, Deduplication, Evidence Preservation
        normalized, evidence = await process_search_results(raw_opportunities)
                
        return {
            "opportunities": normalized,
            "evidence": evidence,
            "sources_checked": list(sources)
        }

def get_research_agent() -> BaseResearchAgent:
    return ResearchAgent()
