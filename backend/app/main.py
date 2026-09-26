from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from app.api.routes import api_router
from app.core.errors import APIError, api_error_handler
import uuid
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="ApplyX Backend",
    version="1.0.0",
    description="FastAPI backend foundation for ApplyX"
)

app.add_exception_handler(APIError, api_error_handler)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    request_id = getattr(request.state, "request_id", "unknown")
    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Invalid request parameters",
                "request_id": request_id
            }
        }
    )

@app.middleware("http")
async def log_requests(request: Request, call_next):
    request.state.request_id = str(uuid.uuid4())
    start_time = time.time()

    response = await call_next(request)

    process_time = (time.time() - start_time) * 1000
    user_id = getattr(request.state, "user_id", "unauthenticated")
    logger.info(
        f"req_id={request.state.request_id} user={user_id} "
        f"method={request.method} path={request.url.path} "
        f"status={response.status_code} latency={process_time:.2f}ms"
    )
    return response

@app.get("/health", tags=["health"])
def health_check_root():
    return {"status": "ok", "version": "1.0.0"}

app.include_router(api_router, prefix="/api/v1")
