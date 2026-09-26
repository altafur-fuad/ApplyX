from fastapi import Request, status
from fastapi.responses import JSONResponse
import uuid
import logging

logger = logging.getLogger(__name__)

class APIError(Exception):
    def __init__(self, code: str, message: str, status_code: int = status.HTTP_400_BAD_REQUEST):
        self.code = code
        self.message = message
        self.status_code = status_code

from typing import cast

async def api_error_handler(request: Request, exc: Exception):
    api_exc = cast(APIError, exc)
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    return JSONResponse(
        status_code=api_exc.status_code,
        content={
            "error": {
                "code": api_exc.code,
                "message": api_exc.message,
                "request_id": request_id
            }
        }
    )
