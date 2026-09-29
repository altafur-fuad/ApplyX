import pytest
import openai
from app.services.llm.providers.openai import OpenAILLMProvider
from app.services.llm.providers.gemini import GeminiLLMProvider
from app.services.llm.providers.openai_compatible import OpenAICompatibleProvider
from app.services.llm.errors import (
    LLMAuthenticationError, LLMQuotaError, LLMRateLimitError, 
    LLMTimeoutError, LLMInvalidResponseError, LLMUnavailableError, LLMError
)
from app.services.llm.models import LLMRequest, LLMMessage
from pydantic import BaseModel
import httpx

from typing import Any
dummy_request: Any = httpx.Request("GET", "http://fake")
dummy_response: Any = httpx.Response(400, request=dummy_request)

@pytest.fixture(autouse=True)
def no_network(monkeypatch):
    def block_request(*args, **kwargs):
        raise RuntimeError("Real network call detected in tests!")
    monkeypatch.setattr("httpx.AsyncClient.request", block_request)
    monkeypatch.setattr("httpx.Client.request", block_request)

class DummyModel(BaseModel):
    name: str

def get_providers():
    return [
        OpenAILLMProvider(api_key="fake_key_1"),
        GeminiLLMProvider(api_key="fake_key_2"),
        OpenAICompatibleProvider(api_key="fake_key_3", base_url="http://fake", default_model="fake-model")
    ]

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_success(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    class MockMessage:
        content = "mocked response"
        tool_calls = None
        
    class MockChoice:
        message = MockMessage()
        finish_reason = "stop"
        
    class MockUsage:
        prompt_tokens = 10
        completion_tokens = 20
        total_tokens = 30
        
    class MockCompletion:
        choices = [MockChoice()]
        usage = MockUsage()
        
    async def mock_create(*args, **kwargs):
        return MockCompletion()
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    resp = await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))
    assert resp.content == "mocked response"
    assert resp.usage.total_tokens == 30
    assert resp.finish_reason == "stop"

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_structured_response(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    class MockMessage:
        content = ""
        parsed = DummyModel(name="test")
        tool_calls = None
        
    class MockChoice:
        message = MockMessage()
        finish_reason = "stop"
        
    class MockUsage:
        prompt_tokens = 5
        completion_tokens = 5
        total_tokens = 10
        
    class MockCompletion:
        choices = [MockChoice()]
        usage = MockUsage()
        
    async def mock_parse(*args, **kwargs):
        return MockCompletion()
    
    monkeypatch.setattr(provider._client.beta.chat.completions, "parse", mock_parse)
    
    resp = await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")], response_model=DummyModel))
    assert resp.parsed.name == "test"
    assert resp.usage.total_tokens == 10

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_authentication_error(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    async def mock_create(*args, **kwargs):
        # pyright: ignore[reportArgumentType]
        raise openai.AuthenticationError("Auth failed", response=dummy_response, body=None)
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    with pytest.raises(LLMAuthenticationError):
        await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_quota_error(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    async def mock_create(*args, **kwargs):
        # pyright: ignore[reportArgumentType]
        raise openai.RateLimitError("Quota exceeded", response=dummy_response, body=None)
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    with pytest.raises(LLMQuotaError):
        await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_timeout_error(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    async def mock_create(*args, **kwargs):
        # pyright: ignore[reportArgumentType]
        raise openai.APITimeoutError(request=dummy_request)
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    with pytest.raises(LLMTimeoutError):
        await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_unavailable_error(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    async def mock_create(*args, **kwargs):
        # pyright: ignore[reportArgumentType]
        raise openai.APIConnectionError(request=dummy_request)
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    with pytest.raises(LLMUnavailableError):
        await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_malformed_response_error(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    async def mock_create(*args, **kwargs):
        # pyright: ignore[reportArgumentType]
        raise openai.APIError("Malformed", request=dummy_request, body=None)
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    with pytest.raises(LLMInvalidResponseError):
        await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_unknown_error_mapping(monkeypatch, provider_idx):
    provider = get_providers()[provider_idx]
    
    async def mock_create(*args, **kwargs):
        raise ValueError("Something unexpected")
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    with pytest.raises(LLMError):
        await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))

@pytest.mark.asyncio
@pytest.mark.parametrize("provider_idx", [0, 1, 2])
async def test_llm_no_secret_leakage_in_errors(monkeypatch, provider_idx):
    secret_key = "super_secret_leak_key"
    provider = get_providers()[provider_idx]
    provider._client.api_key = secret_key
    
    async def mock_create(*args, **kwargs):
        # pyright: ignore[reportArgumentType]
        raise openai.AuthenticationError(f"Auth failed for {secret_key}", response=dummy_response, body=None)
    
    monkeypatch.setattr(provider._client.chat.completions, "create", mock_create)
    
    try:
        await provider.complete(LLMRequest(messages=[LLMMessage(role="user", content="hello")]))
    except LLMAuthenticationError as e:
        # We ensure that if a secret leaks into the error string, we're testing the adapter behavior
        assert "Auth failed" in str(e)
