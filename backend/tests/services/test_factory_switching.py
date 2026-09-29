import pytest
from app.services.llm.factory import get_llm_provider
from app.services.search.factory import get_search_provider
from app.core.config import get_settings
from app.services.llm.providers.mock import MockLLMProvider
from app.services.llm.providers.openai import OpenAILLMProvider
from app.services.llm.providers.gemini import GeminiLLMProvider
from app.services.llm.providers.openai_compatible import OpenAICompatibleProvider
from app.services.search.providers.mock import MockSearchProvider
from app.services.search.providers.tavily import TavilySearchProvider

def test_llm_factory_selection(monkeypatch):
    import app.services.llm.factory as llm_factory
    settings = get_settings()
    
    # 1. Mock
    llm_factory._provider_cache = None
    monkeypatch.setattr(settings, "llm_provider", "mock")
    provider = get_llm_provider()
    assert isinstance(provider._provider, MockLLMProvider)  # type: ignore
    
    # 2. OpenAI
    llm_factory._provider_cache = None
    monkeypatch.setattr(settings, "llm_provider", "openai")
    monkeypatch.setattr(settings, "openai_api_key", "fake")
    provider = get_llm_provider()
    # Factory might wrap it in RetryLLMProviderWrapper, so we check underlying provider
    assert provider.__class__.__name__ == "RetryLLMProviderWrapper"
    assert isinstance(provider._provider, OpenAILLMProvider)  # type: ignore
    
    # 3. Gemini
    llm_factory._provider_cache = None
    monkeypatch.setattr(settings, "llm_provider", "gemini")
    monkeypatch.setattr(settings, "gemini_api_key", "fake")
    provider = get_llm_provider()
    assert isinstance(provider._provider, GeminiLLMProvider)  # type: ignore
    
    # 4. OpenAI Compatible
    llm_factory._provider_cache = None
    monkeypatch.setattr(settings, "llm_provider", "openai_compatible")
    monkeypatch.setattr(settings, "llm_api_key", "fake")
    monkeypatch.setattr(settings, "llm_base_url", "http://fake")
    provider = get_llm_provider()
    assert isinstance(provider._provider, OpenAICompatibleProvider)  # type: ignore

def test_search_factory_selection(monkeypatch):
    import app.services.search.factory as search_factory
    settings = get_settings()
    
    # 1. Mock
    search_factory._provider_cache = None
    monkeypatch.setattr(settings, "search_provider", "mock")
    provider = get_search_provider()
    assert isinstance(provider._provider, MockSearchProvider)  # type: ignore
    
    # 2. Tavily
    search_factory._provider_cache = None
    monkeypatch.setattr(settings, "search_provider", "tavily")
    monkeypatch.setattr(settings, "search_api_key", "fake")
    provider = get_search_provider()
    # Factory might wrap it in RetrySearchProviderWrapper, so we check underlying provider
    assert provider.__class__.__name__ == "RetrySearchProviderWrapper"
    assert isinstance(provider._provider, TavilySearchProvider)  # type: ignore
