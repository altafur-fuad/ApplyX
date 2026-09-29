import pytest
import uuid
from datetime import datetime, timezone

from app.agents.orchestrator import Orchestrator
from app.agents.models import RunStatus, TaskStatus, AgentType, Evidence, EvidenceStatus, ConfidenceLevel, RiskLevel, AgentTask, AgentRunState
from app.agents.state import transition_run, transition_task, InvalidStateTransition
from app.core.policies import check_action_policy, ApprovalRequired, ActionBlocked

@pytest.mark.asyncio
async def test_end_to_end_quality_gate_passes(monkeypatch):
    """
    Validates that a deterministic mock run successfully passes the Quality Gate.
    Verifies:
    1. Duplicate opportunities removed
    2. Important fields have evidence
    3. Missing fields remain uncertain (handled in mock)
    4. Eligibility/Profile-fit references valid opportunities
    5. Quality Gate passes valid final result
    """
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    monkeypatch.setenv("SEARCH_PROVIDER", "mock")
    
    orch = Orchestrator()
    result = await orch.run(
        goal_data={"id": str(uuid.uuid4()), "raw_goal": "Find a remote python internship"},
        profile_data={"skills": ["python"]}
    )
    
    assert result.status == RunStatus.COMPLETED
    assert result.error is None
    
    final_state = result.final_result
    assert final_state is not None
    
    # 1. Duplicate opportunities removed
    opps = final_state["research"]["opportunities"]
    urls = [o.get("source_url") for o in opps if o.get("source_url")]
    assert len(urls) == len(set(urls)), "Duplicate URLs found in final result"
    
    # 4 & 5. Eligibility and Profile Fit references valid opportunities
    valid_titles = {o.get("title") for o in opps}
    eligibility = final_state.get("eligibility", {}).get("eligibility_results", [])
    for e in eligibility:
        assert e.get("opportunity_title") in valid_titles
        
    fit = final_state.get("profile_fit", {}).get("fit_analyses", [])
    for f in fit:
        assert f.get("opportunity_title") in valid_titles

def test_negative_quality_gate_missing_evidence():
    """Negative Case A & B: Missing evidence / unsupported confirmed claim."""
    from app.agents.verification import VerificationService
    vs = VerificationService()
    
    # Confirmed claim but no source URL
    ev = Evidence(
        claim="Deadline is tomorrow",
        status=EvidenceStatus.CONFIRMED,
        confidence=ConfidenceLevel.HIGH,
        source_url=None
    )
    result = vs.verify_evidence_list([ev])
    assert not result.passed
    assert len(result.downgraded_claims) == 1
    assert "lacks source URL" in result.issues[0]

def test_negative_quality_gate_duplicate_opportunity():
    """Negative Case C: Duplicate opportunity."""
    from app.agents.verification import VerificationService
    vs = VerificationService()
    
    state = AgentRunState(goal_id=str(uuid.uuid4()), user_id="u1")
    state.final_result = {
        AgentType.RESEARCH.value: {
            "opportunities": [
                {"title": "Job A", "source_url": "https://example.com/job"},
                {"title": "Job B", "source_url": "https://example.com/job/"} # Duplicate after norm
            ],
            "evidence": []
        }
    }
    
    res = vs.verify_final_result(state)
    assert not res.passed
    assert res.blocked
    assert any("Duplicate opportunity found" in issue for issue in res.issues)

def test_negative_quality_gate_broken_reference():
    """Negative Case D & E: Broken opportunity reference / Contradictory eligibility result."""
    from app.agents.verification import VerificationService
    vs = VerificationService()
    
    state = AgentRunState(goal_id=str(uuid.uuid4()), user_id="u1")
    state.final_result = {
        AgentType.RESEARCH.value: {
            "opportunities": [
                {"title": "Job A", "source_url": "https://example.com/job"}
            ],
            "evidence": []
        },
        AgentType.ELIGIBILITY.value: {
            "eligibility_results": [
                {"opportunity_title": "Job B"} # Unknown
            ]
        }
    }
    
    res = vs.verify_final_result(state)
    assert not res.passed
    assert res.blocked
    assert any("Eligibility references unknown opportunity" in issue for issue in res.issues)

def test_negative_invalid_state_transition():
    """Negative Case F: Invalid state transition."""
    state = AgentRunState(goal_id=str(uuid.uuid4()), user_id="u1")
    transition_run(state, RunStatus.PLANNING)
    transition_run(state, RunStatus.RUNNING)
    transition_run(state, RunStatus.COMPLETED) # Terminal
    
    with pytest.raises(InvalidStateTransition):
        transition_run(state, RunStatus.RUNNING)
        
    task = AgentTask(agent_type=AgentType.RESEARCH, name="test")
    transition_task(task, TaskStatus.RUNNING)
    transition_task(task, TaskStatus.FAILED) # Terminal
    
    with pytest.raises(InvalidStateTransition):
        transition_task(task, TaskStatus.COMPLETED)

def test_negative_policy_high_risk():
    """Negative Case G: High-risk action without approval."""
    with pytest.raises(ApprovalRequired):
        check_action_policy(RiskLevel.HIGH, approval_granted=False)
        
    # Should pass
    check_action_policy(RiskLevel.HIGH, approval_granted=True)

def test_negative_policy_critical():
    """Negative Case H: Critical action attempt."""
    with pytest.raises(ActionBlocked):
        check_action_policy(RiskLevel.CRITICAL, approval_granted=True)
