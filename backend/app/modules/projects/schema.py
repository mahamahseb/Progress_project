from datetime import datetime

from pydantic import BaseModel


class TaskRead(BaseModel):
    title: str
    section: str
    is_completed: bool
    source_line: int
    weight: int = 1


class ProjectCreate(BaseModel):
    name: str
    repo: str
    branch: str = "main"
    prd_path: str = "prd.md"
    project_id: str | None = None


class ProjectSummary(BaseModel):
    id: str
    name: str
    repo: str
    branch: str
    prd_path: str
    progress_percent: int
    total_tasks: int
    completed_tasks: int
    last_commit_sha: str | None = None
    last_synced_at: datetime | None = None


class ProjectDetail(ProjectSummary):
    tasks: list[TaskRead]
