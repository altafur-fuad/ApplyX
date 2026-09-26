from supabase import create_client, Client
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

def get_supabase_client() -> Client:
    """
    Creates and returns a Supabase client using the service role key.

    WARNING: This client bypasses Row Level Security (RLS) and has full database access.
    It should only be used for secure backend operations.
    """
    if not settings.supabase_url or not settings.supabase_service_role_key:
        logger.error("Supabase configuration is missing.")
        raise ValueError("Supabase configuration is missing.")

    client: Client = create_client(
        settings.supabase_url,
        settings.supabase_service_role_key
    )
    return client

# Centralized client instance for easy reuse by future services
supabase: Client = get_supabase_client()
