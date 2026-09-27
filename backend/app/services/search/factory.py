import logging
from typing import Optional
from app.core.config import get_settings
from app.services.search.base import SearchProvider
from app.services.search.providers.mock import MockSearchProvider
from app.services.search.providers.tavily import TavilySearchProvider
from app.services.search.errors import SearchConfigurationError
from app.services.search.retry import RetrySearchProviderWrapper

logger = logging.getLogger(__name__)

_provider_cache: Optional[SearchProvider] = None

def _create_provider_instance(provider_name: str, settings) -> SearchProvider:
    if provider_name == "mock":
        return MockSearchProvider()
    elif provider_name == "tavily":
        if not settings.search_api_key:
            raise SearchConfigurationError("Tavily API key missing")
        return TavilySearchProvider(api_key=settings.search_api_key, base_url=settings.search_base_url)
    else:
        raise SearchConfigurationError(f"Unknown search provider '{provider_name}'")

def get_search_provider(force_provider: Optional[str] = None, disable_fallback: bool = False) -> SearchProvider:
    global _provider_cache
    if _provider_cache is not None and not force_provider:
        return _provider_cache

    settings = get_settings()
    provider_name = force_provider or settings.search_provider or "mock"
    
    provider: SearchProvider
    try:
        provider = _create_provider_instance(provider_name, settings)
    except SearchConfigurationError as e:
        if disable_fallback:
            raise
        fallback = settings.search_fallback_provider
        if fallback:
            logger.warning("SearchProvider '%s' failed to initialize: %s. Falling back to '%s'.", provider_name, str(e), fallback)
            try:
                provider = _create_provider_instance(fallback, settings)
            except Exception as fallback_e:
                raise SearchConfigurationError(f"Fallback search provider '{fallback}' also failed: {fallback_e}") from fallback_e
        else:
            raise
            
    wrapped_provider = RetrySearchProviderWrapper(provider)
    if not force_provider:
        _provider_cache = wrapped_provider
        
    return wrapped_provider
