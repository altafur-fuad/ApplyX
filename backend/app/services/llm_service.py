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
from typing import Any, Dict, List, Optional

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


class LLMResponse(BaseModel):
    """Response from an LLM provider."""
    content: str
    model: str = "mock"
    usage: Dict[str, int] = Field(default_factory=dict)
    finish_reason: Optional[str] = None


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
# Service singleton
# ---------------------------------------------------------------------------

_provider: Optional[LLMProvider] = None


def get_llm_provider() -> LLMProvider:
    """Return the configured LLM provider (defaults to mock)."""
    global _provider
    if _provider is None:
        _provider = MockLLMProvider()
    return _provider


def set_llm_provider(provider: LLMProvider) -> None:
    """Override the LLM provider (useful for tests or real integrations)."""
    global _provider
    _provider = provider
