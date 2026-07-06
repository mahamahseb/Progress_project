from pathlib import Path

from app.core.config import settings
from app.modules.github.client import GitHubClient
from app.modules.progress.calculator import calculate_progress_percent
from app.modules.projects.repository import project_repository
from app.modules.projects.schema import ProjectDetail, TaskRead
from app.modules.sync.log_repository import sync_log_repository
from app.modules.sync.schema import SyncRequest
from app.parsers.prd_parser import parse_prd_markdown


def sync_project_from_prd(payload: SyncRequest) -> ProjectDetail:
    project_id = payload.project_id or payload.repo.replace("/", "__")
    try:
        markdown = _read_prd_markdown(payload)
        parsed = parse_prd_markdown(markdown, fallback_project_name=payload.repo)
        progress_percent = calculate_progress_percent(parsed.tasks)
    except Exception as exc:
        sync_log_repository.create_log(
            project_id=project_id,
            repo=payload.repo,
            commit_sha=payload.commit_sha,
            status="failed",
            message=str(exc),
        )
        raise

    tasks = [
        TaskRead(
            title=task.title,
            section=task.section,
            is_completed=task.is_completed,
            source_line=task.source_line,
            weight=task.weight,
        )
        for task in parsed.tasks
    ]

    project = project_repository.upsert_project(
        project_id=project_id,
        name=parsed.project_name,
        repo=payload.repo,
        branch=payload.branch,
        prd_path=payload.prd_path,
        progress_percent=progress_percent,
        tasks=tasks,
        last_commit_sha=payload.commit_sha,
    )
    sync_log_repository.create_log(
        project_id=project_id,
        repo=payload.repo,
        commit_sha=payload.commit_sha,
        status="success",
        message=f"Synced {len(tasks)} tasks at {progress_percent}%",
    )
    return project


def _read_prd_markdown(payload: SyncRequest) -> str:
    if payload.local_file_path:
        return Path(payload.local_file_path).read_text(encoding="utf-8")

    client = GitHubClient(token=settings.github_token)
    return client.fetch_file(repo=payload.repo, branch=payload.branch, path=payload.prd_path)
