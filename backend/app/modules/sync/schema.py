from datetime import datetime

from pydantic import BaseModel


class SyncRequest(BaseModel):
    repo: str
    branch: str = "main"
    prd_path: str
    commit_sha: str | None = None
    project_id: str | None = None
    local_file_path: str | None = None


class SyncLogRead(BaseModel):
    id: int
    project_id: str
    repo: str
    commit_sha: str | None = None
    status: str
    message: str
    created_at: datetime
