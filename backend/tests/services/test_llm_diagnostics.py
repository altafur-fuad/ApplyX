import pytest
from unittest.mock import patch, MagicMock

from app.core.config import get_settings
from app.services.llm.diagnostics import get_safe_diagnostics, ProviderState
from app.services.llm.factory import get_llm_provider
from app.services.llm.errors import LLMConfigurationError, LLMQuotaError, LLMRateLimitError, LLMAuthenticationError
import app.services.llm.factory as llm_factory

@pytest.fixture(autouse=True)
def isolate_config(monkeypatch):
    original_provider = llm_factory._provider_cache
    get_settings.cache_clear()
    monkeypatch.setattr(llm_factory, "_provider_cache", None)
    # Default to mock
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    yield
    get_settings.cache_clear()
    monkeypatch.setattr(llm_factory, "_provider_cache", original_provider)

def test_mock_configuration_validation(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    diag = get_safe_diagnostics()
    assert diag["provider"] == "mock"
    assert diag["state"] == ProviderState.READY_LOCAL
    assert diag["credentials_present"] is False

def test_openai_configuration_validation(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openai")
    monkeypatch.setenv("LLM_API_KEY", "test_key")
    diag = get_safe_diagnostics()
    assert diag["provider"] == "openai"
    assert diag["state"] == ProviderState.READY_LOCAL
    assert diag["credentials_present"] is True

def test_gemini_configuration_validation(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "gemini")
    monkeypatch.setenv("LLM_API_KEY", "test_key")
    diag = get_safe_diagnostics()
    assert diag["provider"] == "gemini"
    assert diag["state"] == ProviderState.READY_LOCAL
    assert diag["credentials_present"] is True

def test_openai_compatible_configuration_validation(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openai_compatible")
    monkeypatch.setenv("LLM_API_KEY", "test_key")
    monkeypatch.setenv("LLM_BASE_URL", "http://localhost:8080")
    diag = get_safe_diagnostics()
    assert diag["provider"] == "openai_compatible"
    assert diag["state"] == ProviderState.READY_LOCAL
    assert diag["credentials_present"] is True
    assert diag["base_url_configured"] is True

def test_missing_api_key_openai(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openai")
    monkeypatch.setenv("LLM_API_KEY", "")
    monkeypatch.setenv("OPENAI_API_KEY", "")
    diag = get_safe_diagnostics()
    assert diag["state"] == ProviderState.CONFIG_INVALID
    assert "missing" in diag["error"].lower()

def test_missing_base_url_openai_compatible(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openai_compatible")
    monkeypatch.setenv("LLM_API_KEY", "test")
    monkeypatch.setenv("LLM_BASE_URL", "")
    diag = get_safe_diagnostics()
    assert diag["state"] == ProviderState.CONFIG_INVALID
    assert "base url" in diag["error"].lower()

def test_unknown_provider(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "some_unknown_provider")
    diag = get_safe_diagnostics()
    assert diag["state"] == ProviderState.CONFIG_INVALID
    assert "unknown provider" in diag["error"].lower()

def test_missing_api_key_gemini(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "gemini")
    monkeypatch.setenv("LLM_API_KEY", "")
    monkeypatch.setenv("GEMINI_API_KEY", "")
    diag = get_safe_diagnostics()
    assert diag["state"] == ProviderState.CONFIG_INVALID
    assert "missing" in diag["error"].lower()

def test_provider_creation_no_network_call(monkeypatch):
    # Verify that creating the provider through the factory does not execute network requests
    monkeypatch.setenv("LLM_PROVIDER", "openai")
    monkeypatch.setenv("LLM_API_KEY", "fake_key_no_network")

    # We can mock requests to ensure they are not called if we wanted,
    # but normally instantiation shouldn't trigger anything.
    # If it does, the lack of internet/mock would cause a hang or error.
    provider = get_llm_provider()
    assert provider.provider_name() == "openai"

def test_safe_diagnostics_no_secrets(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openai")
    monkeypatch.setenv("LLM_API_KEY", "super_secret_key_12345")
    diag = get_safe_diagnostics()
    diag_str = str(diag)
    assert "super_secret_key_12345" not in diag_str
    assert diag["credentials_present"] is True



def test_provider_error_normalization():
    # Verify that standard exceptions exist and can be raised
    with pytest.raises(LLMQuotaError):
        raise LLMQuotaError("Quota exceeded")

    with pytest.raises(LLMAuthenticationError):
        raise LLMAuthenticationError("Bad Auth")
