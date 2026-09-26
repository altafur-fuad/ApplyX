"""
Tests for Agent Orchestrator and API.
Covers Parts F and G.
"""

from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.agents.models import RunStatus, TaskStatus
from app.agents.orchestrator import Orchestrator
from app.main import app
class MockUser:
    def __init__(self, id: str):
        self.id = id

client = TestClient(app)

def mock_get_current_user():
    return MockUser(id=str(uuid4()))

@pytest.fixture(autouse=True)
def override_get_current_user():
    from app.core.security import get_current_user
    app.dependency_overrides[get_current_user] = mock_get_current_user
    yield
    app.dependency_overrides.clear()


class TestOrchestrator:
    @pytest.mark.asyncio
    async def test_deterministic_end_to_end_agent_run(self):
        orch = Orchestrator()
        result = await orch.run(
            goal_data={"id": str(uuid4()), "raw_goal": "Find software engineering internship"},
            profile_data={"skills": ["python", "fastapi"]},
        )
        assert result.status == RunStatus.COMPLETED
        assert result.plan is not None
        assert len(result.tasks) == 5
        assert all(t.status == TaskStatus.COMPLETED for t in result.tasks)
        assert result.final_result is not None


class TestAPI:
    @patch("app.api.routes.agent_runs.goal_service.get_goal")
    @patch("app.api.routes.agent_runs.agent_run_service.create_agent_run")
    def test_create_agent_run(self, mock_create, mock_get_goal):
        mock_goal_id = str(uuid4())
        mock_get_goal.return_value = {"id": mock_goal_id}
        mock_create.return_value = {
            "id": str(uuid4()),
            "goal_id": mock_goal_id,
            "user_id": str(uuid4()),
            "status": RunStatus.QUEUED.value,
        }

        response = client.post(
            "/api/v1/agent-runs",
            json={"goal_id": str(uuid4()), "mode": "research_and_match"},
        )
        assert response.status_code == 201
        assert response.json()["status"] == "queued"

    @patch("app.api.routes.agent_runs.agent_run_service.get_agent_run")
    def test_get_agent_run(self, mock_get):
        run_id = str(uuid4())
        mock_get.return_value = {
            "id": run_id,
            "goal_id": str(uuid4()),
            "user_id": str(uuid4()),
            "status": RunStatus.RUNNING.value,
        }

        response = client.get(f"/api/v1/agent-runs/{run_id}")
        assert response.status_code == 200
        assert response.json()["status"] == "running"
