from typing import Any, Dict
from app.tools.base import BaseTool
from app.tools.models import ToolDefinition, ToolResult, RetryPolicy
from app.agents.models import RiskLevel
from app.services.search.factory import get_search_provider
from app.services.search.models import SearchRequest, SearchOptions

class SearchTool(BaseTool):
    definition = ToolDefinition(
        name="web_search",
        description="Searches the web for opportunities based on a query.",
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
        timeout_seconds=10,
        retry_policy=RetryPolicy(max_retries=1, retry_on_failure=True),
        idempotent=True
    )

    async def execute(self, input_data: Dict[str, Any]) -> ToolResult:
        query = input_data.get("query")
        if not query:
            return ToolResult(success=False, error="query is required.")

        provider = get_search_provider()
        req = SearchRequest(query=query, options=SearchOptions(max_results=5))
        try:
            response = await provider.search(req)
        except Exception as e:
            return ToolResult(success=False, error=str(e))
        
        results = [r.model_dump(mode="json") for r in response.results]
        return ToolResult(success=True, data={"results": results})
