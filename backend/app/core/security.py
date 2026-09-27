from fastapi import Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.clients.supabase_client import get_supabase_client
from app.core.errors import APIError
from typing import Optional

security = HTTPBearer(auto_error=False)

def get_current_user(request: Request, credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)):
    if not credentials:
        raise APIError(code="AUTH_REQUIRED", message="Authentication is required.", status_code=401)
    
    token = credentials.credentials
    try:
        supabase = get_supabase_client()
        response = supabase.auth.get_user(token)
        if not response or not response.user:
            raise APIError(code="AUTH_REQUIRED", message="Invalid or expired token.", status_code=401)
        # Store for logging/context
        request.state.user_id = response.user.id
        return response.user
    except APIError:
        raise
    except Exception as e:
        raise APIError(code="AUTH_REQUIRED", message="Authentication failed.", status_code=401)
