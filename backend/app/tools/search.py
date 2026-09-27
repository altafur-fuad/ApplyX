from typing import Any, Dict
from app.tools.base import BaseTool
from app.tools.models import ToolDefinition, ToolResult, RetryPolicy
from app.agents.models import RiskLevel
from app.services.search_service import get_search_provider
from datetime import datetime, timezone

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
        results = await provider.search(query)
        
        now = datetime.now(timezone.utc).isoformat()
        for r in results:
            r["fetched_at"] = now
            
        return ToolResult(success=True, data={"results": results})
