"""
LLM service abstraction — future-ready interface for model integration.

Requirements:
- Typed request/response contracts.
- No real provider key needed for tests.
- Deterministic mock implementation.
- Provider-specific code isolated.
- Model outputs treated as untrusted.
"""

from __future__ import annotations

import abc
import logging
import time
from typing import Any, Dict, List, Optional, Type

from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Typed contracts
# ---------------------------------------------------------------------------

class LLMMessage(BaseModel):
    """A single message in a conversation."""
    role: str  # "system", "user", "assistant"
    content: str


class LLMRequest(BaseModel):
    """Request to an LLM provider."""
    messages: List[LLMMessage]
    model: str = "mock"
    temperature: float = 0.0
    max_tokens: int = 1024
    response_format: Optional[str] = None  # "json" for structured output
    response_model: Optional[Type[BaseModel]] = None # For structured outputs
    tools: Optional[List[Dict[str, Any]]] = None
    tool_choice: Optional[str] = None


class LLMResponse(BaseModel):
    """Response from an LLM provider."""
    content: str
    model: str = "mock"
    usage: Dict[str, int] = Field(default_factory=dict)
    finish_reason: Optional[str] = None
    parsed: Optional[Any] = None
    tool_calls: Optional[List[Dict[str, Any]]] = None


class LLMCostRecord(BaseModel):
    """Per-call cost tracking (AGENT_SPEC §14)."""
    provider: str = "mock"
    model: str = "mock"
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    estimated_cost_usd: float = 0.0
    latency_ms: float = 0.0


# ---------------------------------------------------------------------------
# Abstract provider interface
# ---------------------------------------------------------------------------

class LLMProvider(abc.ABC):
    """
    Abstract interface for LLM providers.

    Subclass this to add OpenAI, Gemini, Anthropic, etc.
    """

    @abc.abstractmethod
    async def complete(self, request: LLMRequest) -> LLMResponse:
        """Send a completion request and return the response."""
        ...

    @abc.abstractmethod
    def provider_name(self) -> str:
        """Return the provider identifier string."""
        ...


# ---------------------------------------------------------------------------
# Deterministic mock implementation
# ---------------------------------------------------------------------------

class MockLLMProvider(LLMProvider):
    """
    Deterministic mock that returns canned responses.

    Used in Phase 3 and tests. Never requires a real API key.
    """

    def __init__(self, default_response: str = '{"status": "mock_response"}') -> None:
        self._default_response = default_response
        self._canned: Dict[str, str] = {}

    def set_canned_response(self, key: str, response: str) -> None:
        """Register a canned response for a specific prompt keyword."""
        self._canned[key] = response

    async def complete(self, request: LLMRequest) -> LLMResponse:
        # Check canned responses first
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

        return LLMResponse(
            content=response_content,
            model=request.model,
            usage={
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
                "total_tokens": prompt_tokens + completion_tokens,
            },
            finish_reason="stop",
        )

    def provider_name(self) -> str:
        return "mock"


# ---------------------------------------------------------------------------
# OpenAI implementation
# ---------------------------------------------------------------------------

class OpenAILLMProvider(LLMProvider):
    """Real LLM Provider using OpenAI Python SDK."""
    
    def __init__(self, api_key: str, default_model: str = "gpt-4o-mini") -> None:
        import openai
        self._client = openai.AsyncOpenAI(api_key=api_key)
        self._default_model = default_model

    async def complete(self, request: LLMRequest) -> LLMResponse:
        model = request.model if request.model != "mock" else self._default_model
        
        kwargs: Dict[str, Any] = {
            "model": model,
            "messages": [{"role": m.role, "content": m.content} for m in request.messages],
            "temperature": request.temperature,
            "max_tokens": request.max_tokens,
        }
        
        if request.tools:
            kwargs["tools"] = request.tools
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
                        {
                            "id": tc.id,
                            "type": tc.type,
                            "function": {
                                "name": tc.function.name,
                                "arguments": tc.function.arguments,
                            }
                        }
                        for tc in msg.tool_calls
                    ]
                else:
                    tool_calls = None

            usage_dict = {
                "prompt_tokens": completion.usage.prompt_tokens if completion.usage else 0,
                "completion_tokens": completion.usage.completion_tokens if completion.usage else 0,
                "total_tokens": completion.usage.total_tokens if completion.usage else 0,
            }
            
            finish_reason = completion.choices[0].finish_reason
            
            logger.info(
                "openai_complete model=%s ms=%.0f pt=%d ct=%d finish=%s",
                model,
                (time.time() - start_time) * 1000,
                usage_dict["prompt_tokens"],
                usage_dict["completion_tokens"],
                finish_reason
            )
            
            return LLMResponse(
                content=content,
                model=model,
                usage=usage_dict,
                finish_reason=finish_reason,
                parsed=parsed,
                tool_calls=tool_calls
            )
            
        except Exception as e:
            logger.error("openai_complete failed: %s", str(e))
            raise RuntimeError(f"LLM Provider Error: {str(e)}") from e

    def provider_name(self) -> str:
        return "openai"


# ---------------------------------------------------------------------------
# Service singleton
# ---------------------------------------------------------------------------

_provider: Optional[LLMProvider] = None


def get_llm_provider() -> LLMProvider:
    """Return the configured LLM provider (defaults to mock if no key)."""
    global _provider
    if _provider is None:
        from app.core.config import get_settings
        settings = get_settings()
        if settings.openai_api_key:
            _provider = OpenAILLMProvider(
                api_key=settings.openai_api_key,
                default_model=settings.openai_model or "gpt-4o-mini"
            )
        else:
            logger.warning("OPENAI_API_KEY not found. Falling back to MockLLMProvider.")
            _provider = MockLLMProvider()
    return _provider


def set_llm_provider(provider: LLMProvider) -> None:
    """Override the LLM provider (useful for tests or real integrations)."""
    global _provider
    _provider = provider
