from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.projects import router as projects_router
from app.api.routes.sync import router as sync_router
from app.core.config import settings
from app.db.lifecycle import initialize_database

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    initialize_database()

app.include_router(projects_router, prefix="/api/projects", tags=["projects"])
app.include_router(sync_router, prefix="/api/sync", tags=["sync"])


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}
