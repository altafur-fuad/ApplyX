import logging
from typing import Dict
from app.services.llm.base import LLMProvider
from app.services.llm.models import LLMRequest, LLMResponse, LLMUsage, LLMCapabilities

logger = logging.getLogger(__name__)

class MockLLMProvider(LLMProvider):
    def __init__(self, default_response: str = '{"status": "mock_response"}') -> None:
        self._default_response = default_response
        self._canned: Dict[str, str] = {}
        self._default_model = "mock"

    def provider_name(self) -> str:
        return "mock"
        
    def model_name(self) -> str:
        return self._default_model

    def capabilities(self) -> LLMCapabilities:
        return LLMCapabilities(
            structured_output=True,
            tool_calling=True,
            json_mode=True
        )

    def set_canned_response(self, key: str, response: str) -> None:
        self._canned[key] = response

    async def complete(self, request: LLMRequest) -> LLMResponse:
        user_content = ""
        for msg in request.messages:
            if msg.role == "user":
                user_content = msg.content
                break

        response_content = self._default_response
        for key, canned in self._canned.items():
            if key in user_content:
                response_content = canned
                break

        tool_calls = None

        # Dynamic mock response based on response_model
        if request.response_model:
            model_name = request.response_model.__name__
            if model_name == "AgentPlan":
                import uuid
                t1_id, t2_id, t3_id, t4_id, t5_id = [str(uuid.uuid4()) for _ in range(5)]
                response_content = f"""{{
                    "goal_summary": "Mock plan summary",
                    "constraints": {{}},
                    "tasks": [
                        {{
                            "id": "{t1_id}",
                            "agent_type": "research",
                            "name": "Research opportunities",
                            "status": "pending",
                            "input": {{"constraints": {{}}}},
                            "depends_on": [],
                            "risk_level": "low",
                            "requires_approval": false
                        }},
                        {{
                            "id": "{t2_id}",
                            "agent_type": "eligibility",
                            "name": "Analyze eligibility",
                            "status": "pending",
                            "input": {{}},
                            "depends_on": ["{t1_id}"],
                            "risk_level": "low",
                            "requires_approval": false
                        }},
                        {{
                            "id": "{t3_id}",
                            "agent_type": "profile_fit",
                            "name": "Evaluate profile fit",
                            "status": "pending",
                            "input": {{}},
                            "depends_on": ["{t2_id}"],
                            "risk_level": "low",
                            "requires_approval": false
                        }},
                        {{
                            "id": "{t4_id}",
                            "agent_type": "document",
                            "name": "Prepare application documents",
                            "status": "pending",
                            "input": {{}},
                            "depends_on": ["{t3_id}"],
                            "risk_level": "medium",
                            "requires_approval": false
                        }},
                        {{
                            "id": "{t5_id}",
                            "agent_type": "verification",
                            "name": "Verify results",
                            "status": "pending",
                            "input": {{}},
                            "depends_on": ["{t4_id}"],
                            "risk_level": "low",
                            "requires_approval": false
                        }}
                    ]
                }}"""
            elif model_name == "EligibilityListModel":
                response_content = """{
                    "results": [
                        {
                            "opportunity_title": "Mock Result for ",
                            "eligibility_status": "likely",
                            "met_requirements": ["python"],
                            "missing_requirements": [],
                            "potential_blockers": [],
                            "confidence": "high"
                        }
                    ],
                    "evidence_claims": [
                        "Eligibility for Mock Result for : likely"
                    ]
                }"""
            elif model_name == "ProfileFitListModel":
                response_content = """{
                    "fit_analyses": [
                        {
                            "opportunity_title": "Mock Result for ",
                            "fit_reasons": ["Profile matches requirements: python."],
                            "gaps": [],
                            "overall_fit": "strong"
                        }
                    ]
                }"""

        # Mock tool call for ResearchAgent
        if request.tools and not request.response_model:
            from app.services.llm.models import LLMToolCall
            if any(t.name == "web_search" for t in request.tools):
                response_content = ""
                tool_calls = [
                    LLMToolCall(id="mock_call_1", name="web_search", arguments='{"query": "mock query"}')
                ]

        prompt_tokens = sum(len(m.content.split()) for m in request.messages)
        completion_tokens = len(response_content.split())
        
        logger.info(
            "mock_llm_complete model=%s prompt_tokens=%d completion_tokens=%d",
            request.model,
            prompt_tokens,
            completion_tokens,
        )

        model = request.model if request.model != "mock" else self._default_model

        return LLMResponse(
            content=response_content,
            model=model,
            usage=LLMUsage(
                input_tokens=prompt_tokens,
                output_tokens=completion_tokens,
                total_tokens=prompt_tokens + completion_tokens
            ),
            finish_reason="stop",
            tool_calls=tool_calls
        )
