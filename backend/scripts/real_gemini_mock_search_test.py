import asyncio
import os
import sys
import logging
from typing import Dict, Any

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.config import get_settings
from app.services.llm.diagnostics import get_safe_diagnostics
from app.services.llm.factory import get_llm_provider
from app.services.search.factory import get_search_provider
from app.agents.orchestrator import Orchestrator
from app.agents.models import RunStatus

# Minimal logging
logging.basicConfig(level=logging.CRITICAL)
logging.getLogger("app.agents.orchestrator").setLevel(logging.CRITICAL)

async def main():
    print("========================================")
    print("ApplyX — Real Gemini + Mock Search Test")
    print("========================================")

    # 1. Check Gemini configuration
    diagnostics = get_safe_diagnostics()
    if diagnostics.get("provider") != "gemini":
        print("[FAIL] LLM_PROVIDER is not gemini. Please configure .env")
        sys.exit(1)
        
    if not diagnostics.get("configured") or diagnostics.get("state") == "CONFIG_INVALID":
        print(f"[FAIL] Invalid Gemini configuration: {diagnostics.get('error')}")
        sys.exit(1)

    # 2. Construct existing Gemini provider
    try:
        llm_provider = get_llm_provider()
    except Exception as e:
        print(f"[FAIL] Failed to construct LLM provider: {e}")
        sys.exit(1)

    # 3. Check search configuration
    try:
        search_provider = get_search_provider()
    except Exception as e:
        print(f"[FAIL] Failed to construct Search provider: {e}")
        sys.exit(1)

    print("\nLLM:")
    print(f"provider={llm_provider.provider_name()}")
    print(f"model={llm_provider.model_name()}")
    print("mode=real")

    print("\nSEARCH:")
    print(f"provider={search_provider.provider_name()}")
    print("mode=local")
    
    if search_provider.provider_name() != "mock":
        print("[FAIL] SEARCH_PROVIDER must be mock for this test.")
        sys.exit(1)

    # We want to limit Gemini calls to just the Planner to save requests, 
    # but run the pipeline. So we will intercept the orchestrator or just run it.
    # The requirement: "Prefer one planner request. If one request is enough, stop after one."
    # The safest way is to instantiate PlannerAgent, get the plan, then push it to Verification
    # OR run Orchestrator but mock the LLM factory after planning.
    
    # Actually, the user says: "Use the existing PlannerAgent. Use the existing Mock Search provider. 
    # Execute the existing pipeline as far as safe. Run Verification. Run Quality Gate."
    
    # Let's run the orchestrator with a very simple goal that only requires research, 
    # or just let it run. Mock search returns deterministic results.
    
    print("\n[Executing Pipeline]")
    
    # We will use the orchestrator, but we will limit the tools available to force a simpler plan
    # or we can patch the LLM provider back to mock after the planner generates the plan,
    # ensuring we only use 1 real Gemini request.
    
    import app.services.llm.factory as llm_factory
    from app.services.llm.providers.mock import MockLLMProvider
    from app.services.llm.retry import RetryLLMProviderWrapper
    
    orch = Orchestrator()
    goal_data = {
        "id": "gemini_mock_test_goal",
        "raw_goal": "Find me software engineering jobs in remote locations.",
        "structured_constraints_json": {"job_titles": ["Software Engineer"], "location": "Remote"}
    }
    profile_data = {
        "skills": ["Python", "React"]
    }
    
    # To restrict LLM calls to exactly 1 (for the planner), we will wrap the planner's create_plan
    # to switch the provider to mock immediately after it returns.
    original_create_plan = orch.planner.create_plan
    
    async def wrapped_create_plan(*args, **kwargs):
        import time
        start = time.time()
        try:
            plan = await original_create_plan(*args, **kwargs)
        finally:
            global gemini_latency_ms
            gemini_latency_ms = int((time.time() - start) * 1000)
            # Immediately switch LLM provider to mock to prevent further real API calls
            llm_factory.set_llm_provider(RetryLLMProviderWrapper(MockLLMProvider()))
        return plan
        
    orch.planner.create_plan = wrapped_create_plan
    
    try:
        state = await orch.run(goal_data=goal_data, profile_data=profile_data)
    except Exception as e:
        print(f"[FAIL] Pipeline execution failed safely: {e.__class__.__name__} - {e}")
        # Safe string fallback
        print("planner_status=failed")
        sys.exit(1)
        
    planner_status = "success" if state.plan else "failed"
    plan_validation = "passed" if not state.error or "Plan validation blocked" not in state.error else "failed"
    
    # Check research task specifically
    research_task = next((t for t in state.tasks if t.agent_type.value == "research"), None)
    research_status = research_task.status.value if research_task else "skipped"
    
    if research_status == "completed":
        research_status = "success"
        
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
    print(f"verification_status={verification_status}")
    print(f"quality_gate={quality_gate}")
    print(f"\ngemini_latency_ms={gemini_latency_ms}")

if __name__ == "__main__":
    asyncio.run(main())
