"""
Legacy LLM service module.
Provides backward compatibility. Use app.services.llm.* going forward.
"""
from typing import Any, Dict, List, Optional, Type
from pydantic import BaseModel, Field

# We'll import from the new module
from app.services.llm.models import (
    LLMMessage,
    LLMRequest,
    LLMResponse,
    LLMUsage,
    LLMCapabilities,
    LLMTool,
    LLMToolCall,
)
from app.services.llm.base import LLMProvider
from app.services.llm.providers.mock import MockLLMProvider
from app.services.llm.providers.openai import OpenAILLMProvider
from app.services.llm.factory import get_llm_provider, set_llm_provider

class LLMCostRecord(BaseModel):
    """Per-call cost tracking (AGENT_SPEC §14)."""
    provider: str = "mock"
    model: str = "mock"
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    estimated_cost_usd: float = 0.0
    latency_ms: float = 0.0
