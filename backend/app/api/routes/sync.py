from fastapi import APIRouter, Header, HTTPException

from app.core.config import settings
from app.modules.projects.schema import ProjectDetail
from app.modules.sync.log_repository import sync_log_repository
from app.modules.sync.schema import SyncLogRead, SyncRequest
from app.modules.sync.service import sync_project_from_prd

router = APIRouter()


@router.get("/logs", response_model=list[SyncLogRead])
def list_sync_logs(project_id: str | None = None, limit: int = 50) -> list[SyncLogRead]:
    return sync_log_repository.list_logs(project_id=project_id, limit=limit)


@router.post("/github", response_model=ProjectDetail)
def sync_from_github_action(
    payload: SyncRequest,
    authorization: str | None = Header(default=None),
) -> ProjectDetail:
    expected = f"Bearer {settings.sync_token}"
    if authorization != expected:
        raise HTTPException(status_code=401, detail="Invalid sync token")

    return sync_project_from_prd(payload)
