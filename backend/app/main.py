from fastapi import FastAPI
from app.api.routes import api_router

app = FastAPI(
    title="ApplyX Backend",
    version="1.0.0",
    description="FastAPI backend foundation for ApplyX"
)

@app.get("/health", tags=["health"])
def health_check_root():
    return {"status": "ok", "version": "1.0.0"}

app.include_router(api_router, prefix="/api/v1")
