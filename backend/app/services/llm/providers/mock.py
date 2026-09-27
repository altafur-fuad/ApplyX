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
        )
