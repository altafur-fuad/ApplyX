"""
LLM Service Subsystem.
Provides a provider-agnostic LLM layer supporting mock, openai, gemini, and openai-compatible providers.
"""

from app.services.llm.models import (
    LLMMessage,
    LLMTool,
    LLMToolCall,
    LLMCapabilities,
    LLMRequest,
    LLMUsage,
    LLMResponse,
)
from app.services.llm.base import LLMProvider
from app.services.llm.factory import get_llm_provider, set_llm_provider, get_diagnostics

__all__ = [
    "LLMMessage",
    "LLMTool",
    "LLMToolCall",
    "LLMCapabilities",
    "LLMRequest",
    "LLMUsage",
    "LLMResponse",
    "LLMProvider",
    "get_llm_provider",
    "set_llm_provider",
    "get_diagnostics",
]
