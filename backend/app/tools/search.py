from typing import Any, Dict
from app.tools.base import BaseTool
from app.tools.models import ToolDefinition, ToolResult, RetryPolicy
from app.agents.models import RiskLevel
from app.services.search.factory import get_search_provider
from app.services.search.models import SearchRequest, SearchOptions

class SearchOpportunitiesTool(BaseTool):
    definition = ToolDefinition(
        name="search_opportunities",
        description="Searches for opportunities across approved sources based on a query.",
        input_schema={
            "type": "object",
            "properties": {
                "query": {"type": "string"}
            },
            "required": ["query"]
        },
        output_schema={"type": "object"},
        risk_level=RiskLevel.LOW,
        requires_approval=False,
        timeout_seconds=30,
        retry_policy=RetryPolicy(max_retries=1, retry_on_failure=True),
        idempotent=True
    )

    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        query = input_data.get("query")
        if not query:
            return ToolResult(success=False, error="query is required.")

        results = []
        
        # 1. Fallback / Main provider (e.g., Mock or Tavily)
        provider = get_search_provider()
        req = SearchRequest(query=query, options=SearchOptions(max_results=5))
        try:
            response = await provider.search(req)
            results.extend([r.model_dump(mode="json") for r in response.results])
        except Exception as e:
            pass # Keep going if main provider fails, or log it
            
        # 2. Approved Source Connectors
        from app.services.opportunity.connectors import get_all_connectors
        import logging
        logger = logging.getLogger(__name__)
        
        if provider.provider_name() != "mock":
            for connector in get_all_connectors():
                try:
                    connector_results = await connector.fetch(query)
                    results.extend([r.model_dump(mode="json") for r in connector_results])
                except Exception as e:
                    logger.warning(f"Connector {connector.source_identity()} failed: {e}")
                
        return ToolResult(success=True, data={"results": results})
