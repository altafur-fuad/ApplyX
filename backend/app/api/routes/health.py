from fastapi import APIRouter

router = APIRouter()

@router.get("")
def health_check():
    """
    Health check endpoint to verify the backend is running.
    """
    return {"status": "ok", "version": "1.0.0"}
