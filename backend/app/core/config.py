from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Project Progress Tracker"
    sync_token: str = "dev-token"
    github_token: str | None = None
    sample_prd_path: str = "../examples/sample-project/prd.md"
    database_url: str = "postgresql://progress_tracker:progress_tracker@localhost:5432/progress_tracker"
    cors_origins: str = "http://localhost:3000,http://127.0.0.1:3000"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
