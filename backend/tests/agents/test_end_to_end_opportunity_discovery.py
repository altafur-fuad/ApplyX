import pytest
from app.services.search.models import SearchResult
from app.services.opportunity.pipeline import process_search_results, normalize_search_result, deduplicate_opportunities
from datetime import datetime, timezone

def test_search_result_normalization():
    res = SearchResult(
        title="Software Engineering Intern",
        url="https://jobs.example.com/swe-intern-2027",
        snippet="Example Corp is hiring a Software Engineering Intern. Location: Remote. Requirements: Python, FastAPI. Deadline: 2026-12-01.",
        source_name="example_board",
        retrieved_at=datetime.now(timezone.utc)
    )
    opp, ev = normalize_search_result(res)
    assert opp["title"] == "Software Engineering Intern"
    assert opp["organization"] == "Example Corp"
    assert "Python" in opp["requirements"]
    assert opp["deadline"] == "2026-12-01"

def test_missing_field_handling():
    res = SearchResult(
        title="Frontend Developer",
        url="https://startup.example.com/jobs/1",
        snippet="Looking for a frontend developer. React skills preferred.",
        source_name="startup_site",
        retrieved_at=datetime.now(timezone.utc)
    )
    opp, ev = normalize_search_result(res)
    assert opp["organization"] is None
    assert opp["deadline"] is None
    assert opp["location"] is None
    
def test_deduplication():
    # 1. Exact URL duplicate
    res1 = SearchResult(
        title="Software Engineering Intern",
        url="https://jobs.example.com/swe-intern-2027",
        snippet="Example Corp is hiring a Software Engineering Intern. Location: Remote.",
        source_name="example_board",
        retrieved_at=datetime.now(timezone.utc)
    )
    res2 = SearchResult(
        title="Software Engineering Intern - Example Corp",
        url="https://jobs.example.com/swe-intern-2027",
        snippet="Example Corp is hiring a SWE Intern. Remote role.",
        source_name="aggregator",
        retrieved_at=datetime.now(timezone.utc)
    )
    
    # 2. Distinct Opportunity
    res3 = SearchResult(
        title="Data Science Intern",
        url="https://careers.dataco.example/intern",
        snippet="DataCo is looking for a Data Science intern in New York.",
        source_name="dataco_careers",
        retrieved_at=datetime.now(timezone.utc)
    )
    
    # 3. Title + Org duplicate but different URL
    res4 = SearchResult(
        title="Data Science Intern",
        url="https://aggregator.example/dataco-ds-intern",
        snippet="DataCo is looking for a Data Science intern.",
        source_name="aggregator_site",
        retrieved_at=datetime.now(timezone.utc)
    )
    
    # 4. Missing URL case handled safely
    res5 = SearchResult(
        title="Random Job",
        url="",
        snippet="Example Corp",
        source_name="test",
        retrieved_at=datetime.now(timezone.utc)
    )
    
    opps, ev = process_search_results([res1, res2, res3, res4, res5])
    
    assert len(opps) == 3
    titles = [o["title"] for o in opps]
    assert "Software Engineering Intern" in titles
    assert "Data Science Intern" in titles
    assert "Random Job" in titles
    assert "Software Engineering Intern - Example Corp" not in titles

@pytest.mark.asyncio
async def test_end_to_end_opportunity_discovery_pipeline(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    monkeypatch.setenv("SEARCH_PROVIDER", "mock")
    
    from app.agents.orchestrator import Orchestrator
    from app.agents.models import RunStatus, TaskStatus
    import uuid
    
    orch = Orchestrator()
    result = await orch.run(
        goal_data={"id": str(uuid.uuid4()), "raw_goal": "Find software engineering internship"},
        profile_data={"skills": ["python", "fastapi"]},
    )
    
    assert result.status == RunStatus.COMPLETED
    assert result.plan is not None
    assert len(result.tasks) == 5
    assert all(t.status == TaskStatus.COMPLETED for t in result.tasks)
    
    # Verify the final state holds normalized opportunities
    final_state = result.final_result
    assert final_state is not None
    assert "research" in final_state
    assert "opportunities" in final_state["research"]
    opps = final_state["research"]["opportunities"]
    
    # From the mock search provider, we expect 3 unique opportunities out of 5 raw ones
    assert len(opps) == 3
    titles = [o["title"] for o in opps]
    assert "Software Engineering Intern" in titles
    assert "Data Science Intern" in titles
    assert "Frontend Developer" in titles
    
    # Verify evidence
    evidence = final_state["research"]["evidence"]
    assert len(evidence) > 0
    
    # Eligibility and Profile Fit results
    assert "eligibility" in final_state
    assert "eligibility_results" in final_state["eligibility"]
    
    assert "profile_fit" in final_state
    assert "fit_analyses" in final_state["profile_fit"]
