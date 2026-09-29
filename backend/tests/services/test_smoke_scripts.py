import pytest
import sys
import io
from scripts.llm_smoke_test import run_smoke_test as run_llm_smoke_test
from scripts.search_smoke_test import run_smoke_test as run_search_smoke_test
from app.services.llm.errors import LLMAuthenticationError
from app.services.search.errors import SearchError
from app.core.config import get_settings

@pytest.fixture(autouse=True)
def clear_caches():
    import app.services.llm.factory as llm_factory
    import app.services.search.factory as search_factory
    llm_factory._provider_cache = None
    search_factory._provider_cache = None
    yield
    llm_factory._provider_cache = None
    search_factory._provider_cache = None

@pytest.fixture
def mock_exit(monkeypatch):
    class ExitException(Exception):
        def __init__(self, code):
            self.code = code
    def mock_sys_exit(code=0):
        raise ExitException(code)
    monkeypatch.setattr(sys, 'exit', mock_sys_exit)
    return ExitException

@pytest.mark.asyncio
async def test_llm_smoke_dry_run(capsys, mock_exit):
    with pytest.raises(mock_exit) as exc:
        await run_llm_smoke_test(real=False)
    assert exc.value.code == 0
    output = capsys.readouterr().out
    assert "mode=dry-run" in output
    assert "Run with --real" in output
    assert "REMOTE_VERIFIED" not in output

@pytest.mark.asyncio
async def test_llm_smoke_real_mock_provider(capsys, mock_exit, monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "llm_provider", "mock")
    
    with pytest.raises(mock_exit) as exc:
        await run_llm_smoke_test(real=True)
    assert exc.value.code == 0
    output = capsys.readouterr().out
    assert "mode=real" in output
    assert "provider=mock" in output
    assert "status=READY_LOCAL" in output
    assert "REMOTE_VERIFIED" not in output

@pytest.mark.asyncio
async def test_llm_smoke_real_missing_credential(capsys, mock_exit, monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "llm_provider", "openai")
    monkeypatch.setattr(settings, "openai_api_key", None)
    
    with pytest.raises(mock_exit) as exc:
        await run_llm_smoke_test(real=True)
    assert exc.value.code == 1
    output = capsys.readouterr().out
    assert "CONFIG_INVALID" in output
    assert "REMOTE_VERIFIED" not in output

@pytest.mark.asyncio
async def test_llm_smoke_real_remote_failure(capsys, mock_exit, monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "llm_provider", "openai")
    monkeypatch.setattr(settings, "openai_api_key", "fake_key")
    
    async def mock_complete(*args, **kwargs):
        raise LLMAuthenticationError("Auth failed for fake_key")
    
    # We patch the provider's complete method
    from app.services.llm.providers.openai import OpenAILLMProvider
    monkeypatch.setattr(OpenAILLMProvider, "complete", mock_complete)
    
    with pytest.raises(mock_exit) as exc:
        await run_llm_smoke_test(real=True)
    assert exc.value.code == 1
    output = capsys.readouterr().out
    assert "status=REMOTE_FAILED" in output
    assert "LLMAuthenticationError" in output
    # Ensure secret is not printed in output
    assert "fake_key" not in output.replace("fake_key", "")

@pytest.mark.asyncio
async def test_search_smoke_dry_run(capsys, mock_exit):
    with pytest.raises(mock_exit) as exc:
        await run_search_smoke_test(real=False)
    assert exc.value.code == 0
    output = capsys.readouterr().out
    assert "mode=dry-run" in output
    assert "REMOTE_VERIFIED" not in output

@pytest.mark.asyncio
async def test_search_smoke_real_mock_provider(capsys, mock_exit, monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "search_provider", "mock")
    
    with pytest.raises(mock_exit) as exc:
        await run_search_smoke_test(real=True)
    assert exc.value.code == 0
    output = capsys.readouterr().out
    assert "mode=real" in output
    assert "provider=mock" in output
    assert "status=READY_LOCAL" in output
    assert "REMOTE_VERIFIED" not in output

@pytest.mark.asyncio
async def test_search_smoke_real_missing_credential(capsys, mock_exit, monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "search_provider", "tavily")
    monkeypatch.setattr(settings, "search_api_key", None)
    
    with pytest.raises(mock_exit) as exc:
        await run_search_smoke_test(real=True)
    assert exc.value.code == 1
    output = capsys.readouterr().out
    assert "CONFIG_INVALID" in output
    assert "REMOTE_VERIFIED" not in output
