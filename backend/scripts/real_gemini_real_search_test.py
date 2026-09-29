import asyncio
import os
import sys
import logging
import time
from typing import Dict, Any

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Ensure config loads fresh
from app.core.config import get_settings
get_settings.cache_clear()

from app.services.search.diagnostics import get_safe_search_diagnostics
from app.services.llm.diagnostics import get_safe_diagnostics
import app.services.llm.factory as llm_factory
import app.services.search.factory as search_factory
from app.agents.orchestrator import Orchestrator
from app.agents.models import RunStatus

# Minimal logging
logging.basicConfig(level=logging.CRITICAL)
logging.getLogger("app.agents.orchestrator").setLevel(logging.CRITICAL)
logging.getLogger("httpx").setLevel(logging.CRITICAL)

async def main():
    print("========================================")
    print("ApplyX — Real Gemini + Real Tavily Search")
    print("========================================")

    # 1. Check Gemini configuration
    llm_diag = get_safe_diagnostics()
    if llm_diag.get("provider") != "gemini":
        print("[FAIL] LLM_PROVIDER is not gemini. Please configure .env")
        sys.exit(1)
        
    if not llm_diag.get("configured") or llm_diag.get("state") == "CONFIG_INVALID":
        print(f"[FAIL] Invalid LLM configuration: {llm_diag.get('error')}")
        sys.exit(1)

    # 2. Check Search configuration
    search_diag = get_safe_search_diagnostics()
    if search_diag.get("provider") != "tavily":
        print("[FAIL] SEARCH_PROVIDER is not tavily. Please configure .env")
        sys.exit(1)
        
    if not search_diag.get("configured") or search_diag.get("state") == "CONFIG_INVALID":
        print(f"[FAIL] Invalid Search configuration: {search_diag.get('error')}")
        sys.exit(1)

    # 3. Construct providers to ensure initialization succeeds
    try:
        original_llm_provider = llm_factory.get_llm_provider()
    except Exception as e:
        print(f"[FAIL] Failed to construct LLM provider: {e}")
        sys.exit(1)
        
    try:
        original_search_provider = search_factory.get_search_provider()
    except Exception as e:
        print(f"[FAIL] Failed to construct Search provider: {e}")
        sys.exit(1)

    print("\nLLM:")
    print(f"provider={original_llm_provider.provider_name()}")
    print(f"model={original_llm_provider.model_name()}")
    print("mode=real")

    print("\nSEARCH:")
    print(f"provider={original_search_provider.provider_name()}")
    print("mode=real")
    
    print("\n[Executing Pipeline]")
    
    # 4. Wrap providers to measure latency
    gemini_latency_ms = 0
    search_latency_ms = 0
    result_count = 0
    
    def wrapped_get_llm_provider():
        provider = original_llm_provider
        original_complete = provider.complete
        
        async def wrapped_complete(*args, **kwargs):
            nonlocal gemini_latency_ms
            start = time.time()
            try:
                return await original_complete(*args, **kwargs)
            finally:
                gemini_latency_ms += int((time.time() - start) * 1000)
                
        provider.complete = wrapped_complete
        return provider
        
    def wrapped_get_search_provider():
        provider = original_search_provider
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
        
    llm_factory.get_llm_provider = wrapped_get_llm_provider
    search_factory.get_search_provider = wrapped_get_search_provider
    
    # 5. Initialize Orchestrator and run
    orch = Orchestrator()
    goal_data = {
        "id": "e2e_gemini_tavily_test",
        "raw_goal": "Find me software engineering internships open 2024 github remote",
        "structured_constraints_json": {"job_titles": ["Software Engineer Intern"], "location": "Remote"}
    }
    profile_data = {
        "skills": ["Python", "React", "Git"]
    }
    
    start_total = time.time()
    try:
        state = await orch.run(goal_data=goal_data, profile_data=profile_data)
    except Exception as e:
        print(f"[FAIL] Pipeline execution failed safely: {e.__class__.__name__} - {e}")
        print("Final:\nREAL_LLM=FAIL\nREAL_SEARCH=FAIL\nE2E=FAIL")
        sys.exit(1)
        
    total_latency_ms = int((time.time() - start_total) * 1000)
    
    planner_status = "success" if state.plan else "failed"
    plan_validation = "passed" if not state.error or "Plan validation blocked" not in state.error else "failed"
    
    # Check research task specifically
    research_task = next((t for t in state.tasks if t.agent_type.value == "research"), None)
    research_status = "success" if research_task and research_task.status.value == "completed" else "failed"
    
    verification_status = "passed"
    quality_gate = "passed"
    
    if state.status == RunStatus.FAILED:
        if state.error and "Quality Gate" in state.error:
            quality_gate = "failed"
        elif state.error and "Plan validation" in state.error:
            plan_validation = "failed"
        else:
            verification_status = "failed"
            
    print(f"\nplanner_status={planner_status}")
    print(f"plan_validation={plan_validation}")
    print(f"research_status={research_status}")
    print(f"result_count={result_count}")
    print(f"verification_status={verification_status}")
    print(f"quality_gate={quality_gate}")
    print(f"\ngemini_latency_ms={gemini_latency_ms}")
    print(f"search_latency_ms={search_latency_ms}")
    print(f"total_latency_ms={total_latency_ms}")
    
    real_llm = "PASS" if planner_status == "success" else "FAIL"
    real_search = "PASS" if research_status == "success" else "FAIL"
    e2e = "PASS" if quality_gate == "passed" and verification_status == "passed" and real_llm == "PASS" and real_search == "PASS" else "FAIL"
    
    print("\nFinal:")
    print(f"REAL_LLM={real_llm}")
    print(f"REAL_SEARCH={real_search}")
    print(f"E2E={e2e}")

if __name__ == "__main__":
    asyncio.run(main())
