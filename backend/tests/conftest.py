import os
import pytest
from app.core.config import get_settings

# Force offline/mock configuration for all normal pytest runs
os.environ["LLM_PROVIDER"] = "mock"
os.environ["SEARCH_PROVIDER"] = "mock"

# Clear settings cache in case it was already loaded
get_settings.cache_clear()

@pytest.fixture(autouse=True)
def force_mock_providers(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "llm_provider", "mock")
    monkeypatch.setattr(settings, "search_provider", "mock")
    # clear real keys from settings to prevent accidentally hitting external endpoints
    monkeypatch.setattr(settings, "llm_api_key", None)
    monkeypatch.setattr(settings, "openai_api_key", None)
    monkeypatch.setattr(settings, "gemini_api_key", None)
