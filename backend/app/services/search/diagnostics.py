from enum import Enum
from typing import Any, Dict
from app.core.config import get_settings
from app.services.search.factory import get_search_provider
from app.services.search.errors import SearchConfigurationError

class SearchProviderState(str, Enum):
    NOT_CONFIGURED = "NOT_CONFIGURED"
    CONFIG_INVALID = "CONFIG_INVALID"
    READY_LOCAL = "READY_LOCAL"
    REMOTE_VERIFIED = "REMOTE_VERIFIED"
    REMOTE_FAILED = "REMOTE_FAILED"

def get_safe_search_diagnostics() -> Dict[str, Any]:
    settings = get_settings()
    provider_name = settings.search_provider
    fallback = settings.search_fallback_provider
    
    state = SearchProviderState.NOT_CONFIGURED
    
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
    
    if provider_name == "tavily":
        credentials_present = bool(settings.search_api_key)
        base_url_configured = bool(settings.search_base_url)
    elif provider_name == "mock":
        pass

    try:
        provider = get_search_provider(force_provider=provider_name, disable_fallback=True)
        state = SearchProviderState.READY_LOCAL
        caps = provider.capabilities().model_dump()
    except SearchConfigurationError as e:
        state = SearchProviderState.CONFIG_INVALID
        error_msg = str(e)
        caps = None
    except Exception as e:
        state = SearchProviderState.CONFIG_INVALID
        error_msg = str(e)
        caps = None

    return {
        "provider": provider_name,
        "fallback_provider": fallback,
        "state": state.value,
        "configured": state != SearchProviderState.NOT_CONFIGURED,
        "credentials_present": credentials_present,
        "base_url_configured": base_url_configured,
        "capabilities": caps,
        "error": error_msg
    }
