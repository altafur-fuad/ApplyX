from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    """
    Application configuration settings.
    Reads from environment variables and .env file.
    """
    # Supabase Configuration
    supabase_url: str = Field(..., env='SUPABASE_URL', description="Supabase project URL")
    
    # WARNING: This key must NEVER be exposed to the client. It grants admin privileges.
    supabase_service_role_key: str = Field(..., env='SUPABASE_SERVICE_ROLE_KEY', description="Supabase service role key (backend only)")
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )

settings = Settings()
