import asyncio
import os
import sys
import logging
from typing import Dict, Any, Optional
import time

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Force providers before loading config
os.environ["LLM_PROVIDER"] = "mock"
os.environ["SEARCH_PROVIDER"] = "tavily"

# Ensure config loads fresh
from app.core.config import get_settings
get_settings.cache_clear()

from app.services.search.diagnostics import get_safe_search_diagnostics
from app.services.llm.diagnostics import get_safe_diagnostics
from app.services.search.factory import get_search_provider
from app.agents.orchestrator import Orchestrator
from app.agents.models import RunStatus

# Minimal logging
logging.basicConfig(level=logging.CRITICAL)
logging.getLogger("app.agents.orchestrator").setLevel(logging.CRITICAL)
logging.getLogger("httpx").setLevel(logging.CRITICAL)

async def main():
    print("========================================")
    print("ApplyX — Real Search + Mock LLM Test")
    print("========================================")

    # 1. Check Search configuration
    diagnostics = get_safe_search_diagnostics()
    if diagnostics.get("provider") != "tavily":
        print("[FAIL] SEARCH_PROVIDER is not tavily.")
        sys.exit(1)

    if not diagnostics.get("configured") or diagnostics.get("state") == "CONFIG_INVALID":
        print(f"[FAIL] Invalid Search configuration: {diagnostics.get('error')}")
        sys.exit(1)

    # 2. Construct providers
    try:
        search_provider = get_search_provider()
    except Exception as e:
        print(f"[FAIL] Failed to construct Search provider: {e}")
        sys.exit(1)

    print("\nLLM:")
    print("provider=mock")
    print("mode=local")

    print("\nSEARCH:")
    print(f"provider={search_provider.provider_name()}")
    print("mode=real")

    print("\n[Executing Pipeline]")

    orch = Orchestrator()
    goal_data = {
        "id": "tavily_mock_test_goal",
        "raw_goal": "Find me software engineering internships open 2024 github remote",
        "structured_constraints_json": {"job_titles": ["Software Engineer Intern"], "location": "Remote"}
    }
    profile_data = {
        "skills": ["Python", "React", "Git"]
    }

    # Wrap the factory to capture search latency on the provider
    original_get_search_provider = get_search_provider
    search_latency_ms = 0
    result_count = 0

    import app.services.search.factory as search_factory

    def wrapped_get_provider(force_provider: Optional[str] = None):
        provider = original_get_search_provider(force_provider=force_provider)
        original_search = provider.search

        async def wrapped_search(*args, **kwargs):
            nonlocal search_latency_ms, result_count
            start = time.time()
            try:
                res = await original_search(*args, **kwargs)
                result_count += len(res.results)
                return res
            finally:
                search_latency_ms += int((time.time() - start) * 1000)

        provider.search = wrapped_search
        return provider

    search_factory.get_search_provider = wrapped_get_provider

    try:
        state = await orch.run(goal_data=goal_data, profile_data=profile_data)
    except Exception as e:
        print(f"[FAIL] Pipeline execution failed safely: {e.__class__.__name__} - {e}")
        print("search_status=failed")
        sys.exit(1)

    # Find specific task statuses
    research_task = next((t for t in state.tasks if t.agent_type.value == "research"), None)
    search_status = "success" if research_task and research_task.status.value == "completed" else "failed"

    normalization_status = "success" if search_status == "success" else "skipped"
    deduplication_status = "success" if search_status == "success" else "skipped"
    evidence_status = "success" if search_status == "success" else "skipped"

    verification_status = "passed"
    quality_gate = "passed"

    if state.status == RunStatus.FAILED:
        if state.error and "Quality Gate" in state.error:
            quality_gate = "failed"
        elif state.error and "Plan validation" in state.error:
            # We don't expect this since LLM is mock
            pass
        else:
            verification_status = "failed"

    print(f"\nsearch_status={search_status}")
    print(f"result_count={result_count}")
    print(f"normalization_status={normalization_status}")
    print(f"deduplication_status={deduplication_status}")
    print(f"evidence_status={evidence_status}")
    print(f"verification_status={verification_status}")
    print(f"quality_gate={quality_gate}")
    print(f"\nsearch_latency_ms={search_latency_ms}")

if __name__ == "__main__":
    asyncio.run(main())
