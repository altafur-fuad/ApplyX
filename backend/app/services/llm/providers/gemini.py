import time
import logging
from typing import Any, Dict
from app.services.llm.base import LLMProvider
from app.services.llm.models import LLMRequest, LLMResponse, LLMUsage, LLMCapabilities, LLMToolCall
from app.services.llm.errors import (
    LLMAuthenticationError, LLMQuotaError, LLMRateLimitError, 
    LLMTimeoutError, LLMInvalidResponseError, LLMError, LLMUnavailableError
)

logger = logging.getLogger(__name__)

class GeminiLLMProvider(LLMProvider):
    """
    Implements Gemini using their official OpenAI compatibility layer.
    """
    def __init__(self, api_key: str, default_model: str = "gemini-1.5-flash") -> None:
        import openai
        self._client = openai.AsyncOpenAI(
            api_key=api_key,
            base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
            max_retries=0,
            timeout=60.0
        )
        self._default_model = default_model

    def provider_name(self) -> str:
        return "gemini"

    def model_name(self) -> str:
        return self._default_model

    def capabilities(self) -> LLMCapabilities:
        return LLMCapabilities(
            structured_output=True, 
            tool_calling=True,
            json_mode=True
        )

    def _translate_error(self, e: Exception) -> Exception:
        import openai
        if isinstance(e, openai.AuthenticationError):
            return LLMAuthenticationError(str(e))
        if isinstance(e, openai.RateLimitError):
            if "quota" in str(e).lower():
                return LLMQuotaError(str(e))
            return LLMRateLimitError(str(e))
        if isinstance(e, openai.APITimeoutError):
            return LLMTimeoutError(str(e))
        if isinstance(e, openai.APIConnectionError):
            return LLMUnavailableError(str(e))
        if isinstance(e, openai.APIError):
            return LLMInvalidResponseError(str(e))
        return LLMError(str(e))

    async def complete(self, request: LLMRequest) -> LLMResponse:
        model = request.model if request.model != "mock" else self._default_model
        
        kwargs: Dict[str, Any] = {
            "model": model,
            "messages": [{"role": m.role, "content": m.content} for m in request.messages],
            "temperature": request.temperature,
            "max_tokens": request.max_tokens,
        }
        
        if request.tools:
            kwargs["tools"] = [
                {
                    "type": "function",
                    "function": {
                        "name": t.name,
                        "description": t.description,
                        "parameters": t.input_schema
                    }
                }
                for t in request.tools
            ]
        if request.tool_choice:
            kwargs["tool_choice"] = request.tool_choice
            
        start_time = time.time()
        
        try:
            if request.response_model:
                completion = await self._client.beta.chat.completions.parse(
                    response_format=request.response_model,
                    **kwargs
                )
                msg = completion.choices[0].message
                content = msg.content or ""
                parsed = msg.parsed if hasattr(msg, "parsed") else None
                tool_calls = None
            else:
                if request.response_format == "json":
                    kwargs["response_format"] = {"type": "json_object"}
                    
                completion = await self._client.chat.completions.create(**kwargs)
                msg = completion.choices[0].message
                content = msg.content or ""
                parsed = None
                
                if msg.tool_calls:
                    tool_calls = [
                        LLMToolCall(
                            id=tc.id,
                            name=tc.function.name,
                            arguments=tc.function.arguments,
                        )
                        for tc in msg.tool_calls
                    ]
                else:
                    tool_calls = None

            usage = LLMUsage()
            if completion.usage:
                usage.input_tokens = completion.usage.prompt_tokens
                usage.output_tokens = completion.usage.completion_tokens
                usage.total_tokens = completion.usage.total_tokens

            finish_reason = completion.choices[0].finish_reason
            
            logger.info(
                "gemini_complete model=%s ms=%.0f pt=%d ct=%d finish=%s",
                model,
                (time.time() - start_time) * 1000,
                usage.input_tokens,
                usage.output_tokens,
                finish_reason
            )
            
            return LLMResponse(
                content=content,
                model=model,
                usage=usage,
                finish_reason=finish_reason,
                parsed=parsed,
                tool_calls=tool_calls
            )
            
        except Exception as e:
            logger.error("gemini_complete failed: %s", str(e))
            raise self._translate_error(e) from e
