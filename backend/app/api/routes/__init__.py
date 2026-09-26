from fastapi import APIRouter
from app.api.routes import health, profiles, goals, opportunities, applications, agent_runs

api_router = APIRouter()
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(profiles.router, prefix="/profiles", tags=["profiles"])
api_router.include_router(goals.router, prefix="/goals", tags=["goals"])
api_router.include_router(opportunities.router, prefix="/opportunities", tags=["opportunities"])
api_router.include_router(applications.router, prefix="/applications", tags=["applications"])
api_router.include_router(agent_runs.router, prefix="/agent-runs", tags=["agent-runs"])
