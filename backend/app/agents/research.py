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

from app.agents.models import Evidence, EvidenceStatus, ConfidenceLevel

logger = logging.getLogger(__name__)


class BaseResearchAgent(abc.ABC):
    @abc.abstractmethod
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        ...

class ResearchAgent(BaseResearchAgent):
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        provider = get_llm_provider()
        registry = get_tool_registry()
        
        system_prompt = """You are the ApplyX Research Agent.
Your goal is to find relevant opportunities. You have access to the web_search tool.
Formulate a search query based on the constraints provided, and call the web_search tool.
Do NOT invent opportunities or evidence.
"""
        user_prompt = f"Constraints: {json.dumps(input_data.get('constraints', {}))}"
        
        from app.services.llm.models import LLMTool
        search_tool = registry.get("web_search")
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
                if tc.name == "web_search":
                    try:
                        args = json.loads(tc.arguments)
                    except:
                        args = {}
                    
                    record = await registry.execute("web_search", args)
                    if record.status == "completed" and record.output_data:
                        results = record.output_data.get("results", [])
                        raw_opportunities.extend(results)
                        sources.update([r.get("source_name", "web_search") for r in results])

        normalized = []
        evidence = []
        now = datetime.now(timezone.utc)
        
        for opp in raw_opportunities:
            norm_rec = await registry.execute("normalize_opportunity", {"raw_data": opp})
            if norm_rec.status == "completed" and norm_rec.output_data:
                norm_opp = norm_rec.output_data
                normalized.append(norm_opp)
                
                evidence.append(
                    Evidence(
                        claim=f"Opportunity found: {norm_opp.get('title')}",
                        status=EvidenceStatus.CONFIRMED,
                        source_url=norm_opp.get("source_url"),
                        retrieved_at=now,
                        confidence=ConfidenceLevel.HIGH,
                        evidence_type="opportunity_listing"
                    ).model_dump(mode="json")
                )
                
        return {
            "opportunities": normalized,
            "evidence": evidence,
            "sources_checked": list(sources)
        }

def get_research_agent() -> BaseResearchAgent:
    return ResearchAgent()
