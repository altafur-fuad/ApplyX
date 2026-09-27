from enum import Enum
from typing import Any, Dict
from app.core.config import get_settings
from app.services.llm.factory import get_llm_provider
from app.services.llm.errors import LLMConfigurationError

class ProviderState(str, Enum):
    NOT_CONFIGURED = "NOT_CONFIGURED"
    CONFIG_INVALID = "CONFIG_INVALID"
    READY_LOCAL = "READY_LOCAL"
    REMOTE_VERIFIED = "REMOTE_VERIFIED"
    REMOTE_FAILED = "REMOTE_FAILED"

def get_safe_diagnostics() -> Dict[str, Any]:
    """Safe diagnostics for health checks. Never exposes secrets."""
    settings = get_settings()
    provider_name = settings.llm_provider
    fallback = settings.llm_fallback_provider
    
    state = ProviderState.NOT_CONFIGURED
    
    if not provider_name:
        return {
            "provider": None,
            "state": state.value,
            "configured": False,
            "credentials_present": False,
            "base_url_configured": False,
            "capabilities": None
        }

    credentials_present = False
    base_url_configured = False
    error_msg = None
    
    if provider_name == "openai":
        credentials_present = bool(settings.llm_api_key or settings.openai_api_key)
    elif provider_name == "gemini":
        credentials_present = bool(settings.llm_api_key or settings.gemini_api_key)
    elif provider_name == "openai_compatible":
        credentials_present = bool(settings.llm_api_key)
        base_url_configured = bool(settings.llm_base_url)
    elif provider_name == "mock":
        pass

    try:
        provider = get_llm_provider(force_provider=provider_name, disable_fallback=True)
        state = ProviderState.READY_LOCAL
        model = provider.model_name()
        caps = provider.capabilities().model_dump()
    except LLMConfigurationError as e:
        state = ProviderState.CONFIG_INVALID
        error_msg = str(e)
        model = None
        caps = None
    except Exception as e:
        state = ProviderState.CONFIG_INVALID
        error_msg = str(e)
        model = None
        caps = None

    return {
        "provider": provider_name,
        "fallback_provider": fallback,
        "model": model,
        "state": state.value,
        "configured": state != ProviderState.NOT_CONFIGURED,
        "credentials_present": credentials_present,
        "base_url_configured": base_url_configured,
        "capabilities": caps,
        "error": error_msg
    }
