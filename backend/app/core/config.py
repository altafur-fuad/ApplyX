from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field
from functools import lru_cache
from typing import Optional

class Settings(BaseSettings):
    """
    Application configuration settings.
    Reads from environment variables and .env file.
    """
    # Supabase Configuration
    supabase_url: str = Field(..., description="Supabase project URL")

    # WARNING: This key must NEVER be exposed to the client. It grants admin privileges.
    supabase_service_role_key: str = Field(..., description="Supabase service role key (backend only)")

    # OpenAI Configuration
    openai_api_key: Optional[str] = Field(None, description="OpenAI API Key")
    openai_model: Optional[str] = Field(None, description="OpenAI Model Name (e.g., gpt-4o)")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )

@lru_cache()
def get_settings() -> Settings:
    return Settings() # type: ignore
