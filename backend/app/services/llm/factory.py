import logging
from typing import Optional, Dict, Any
from app.core.config import get_settings
from app.services.llm.base import LLMProvider
from app.services.llm.providers.mock import MockLLMProvider
from app.services.llm.providers.openai import OpenAILLMProvider
from app.services.llm.providers.gemini import GeminiLLMProvider
from app.services.llm.providers.openai_compatible import OpenAICompatibleProvider
from app.services.llm.errors import LLMConfigurationError
from app.services.llm.retry import RetryLLMProviderWrapper

logger = logging.getLogger(__name__)

_provider_cache: Optional[LLMProvider] = None

def get_llm_provider(force_provider: Optional[str] = None) -> LLMProvider:
    """
    Returns a configured LLM provider instance.
    Uses fallback semantics from configuration if necessary.
    """
    global _provider_cache
    if _provider_cache is not None and not force_provider:
        return _provider_cache

    settings = get_settings()
    
    # Resolve provider name
    provider_name = force_provider or settings.llm_provider or "mock"
    
    provider: LLMProvider
    
    if provider_name == "mock":
        provider = MockLLMProvider()
    elif provider_name == "openai":
        api_key = settings.llm_api_key or settings.openai_api_key
        if not api_key:
            # Fallback
            if settings.llm_fallback_provider == "mock":
                logger.warning("OpenAI API key missing. Falling back to Mock.")
                provider = MockLLMProvider()
            else:
                raise LLMConfigurationError("OpenAI API key missing")
        else:
            provider = OpenAILLMProvider(api_key=api_key, default_model=settings.llm_model or settings.openai_model or "gpt-4o-mini")
    elif provider_name == "gemini":
        api_key = settings.llm_api_key or settings.gemini_api_key
        if not api_key:
            if settings.llm_fallback_provider == "mock":
                logger.warning("Gemini API key missing. Falling back to Mock.")
                provider = MockLLMProvider()
            else:
                raise LLMConfigurationError("Gemini API key missing")
        else:
            provider = GeminiLLMProvider(api_key=api_key, default_model=settings.llm_model or "gemini-1.5-flash")
    elif provider_name == "openai_compatible":
        if not settings.llm_api_key or not settings.llm_base_url:
            if settings.llm_fallback_provider == "mock":
                logger.warning("OpenAI Compatible provider needs API key and base URL. Falling back to Mock.")
                provider = MockLLMProvider()
            else:
                raise LLMConfigurationError("OpenAI Compatible provider needs API key and base URL")
        else:
            provider = OpenAICompatibleProvider(
                api_key=settings.llm_api_key,
                base_url=settings.llm_base_url,
                default_model=settings.llm_model or "default"
            )
    else:
        # Check fallback
        if settings.llm_fallback_provider == "mock":
            logger.warning(f"Unknown provider '{provider_name}'. Falling back to Mock.")
            provider = MockLLMProvider()
        else:
            raise LLMConfigurationError(f"Unknown provider '{provider_name}'")
            
    wrapped_provider = RetryLLMProviderWrapper(provider)
    if not force_provider:
        _provider_cache = wrapped_provider
        
    return wrapped_provider

def set_llm_provider(provider: LLMProvider) -> None:
    """Override the global provider."""
    global _provider_cache
    _provider_cache = provider

def get_diagnostics() -> Dict[str, Any]:
    """Safe diagnostics for health checks."""
    try:
        provider = get_llm_provider()
        return {
            "provider": provider.provider_name(),
            "model": provider.model_name(),
            "configured": True,
            "credentials_present": True,
            "capabilities": provider.capabilities().model_dump()
        }
    except Exception as e:
        return {
            "provider": "unknown",
            "model": "unknown",
            "configured": False,
            "credentials_present": False,
            "capabilities": None,
            "error": str(e)
        }
