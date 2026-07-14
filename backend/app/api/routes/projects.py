from fastapi import APIRouter, HTTPException
from psycopg.errors import UniqueViolation

from app.modules.projects.repository import project_repository
from app.modules.projects.schema import ProjectCreate, ProjectDetail, ProjectSummary

router = APIRouter()


@router.get("", response_model=list[ProjectSummary])
def list_projects() -> list[ProjectSummary]:
    return project_repository.list_projects()


@router.post("", response_model=ProjectDetail, status_code=201)
def create_project(payload: ProjectCreate) -> ProjectDetail:
    try:
        return project_repository.create_project(payload)
    except UniqueViolation as exc:
        raise HTTPException(status_code=409, detail="Project already exists") from exc


@router.get("/{project_id}", response_model=ProjectDetail)
def get_project(project_id: str) -> ProjectDetail:
    project = project_repository.get_project(project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return project
