import os

from app.db.schema import init_db
from app.modules.projects.repository import ProjectRepository
from app.modules.projects.schema import ProjectCreate, TaskRead


def prepare_database(monkeypatch) -> None:
    database_url = os.environ.get(
        "TEST_DATABASE_URL",
        "postgresql://progress_tracker:progress_tracker@localhost:5432/progress_tracker_test",
    )
    monkeypatch.setattr("app.core.config.settings.database_url", database_url)

    from app.db import session

    with session.get_connection() as connection:
        init_db(connection)
        connection.execute("TRUNCATE sync_logs, tasks, projects RESTART IDENTITY CASCADE")
        connection.commit()


def test_project_repository_persists_projects(monkeypatch) -> None:
    prepare_database(monkeypatch)

    repository = ProjectRepository()
    repository.upsert_project(
        project_id="owner__repo",
        name="Repo",
        repo="owner/repo",
        branch="main",
        prd_path="prd.md",
        progress_percent=50,
        tasks=[
            TaskRead(
                title="Done",
                section="Backend",
                is_completed=True,
                source_line=3,
                weight=1,
            ),
            TaskRead(
                title="Todo",
                section="Backend",
                is_completed=False,
                source_line=4,
                weight=1,
            ),
        ],
        last_commit_sha="abc123",
    )

    fresh_repository = ProjectRepository()
    project = fresh_repository.get_project("owner__repo")

    assert project is not None
    assert project.progress_percent == 50
    assert project.completed_tasks == 1
    assert len(project.tasks) == 2
    assert fresh_repository.list_projects()[0].name == "Repo"


def test_project_repository_creates_registered_project(monkeypatch) -> None:
    prepare_database(monkeypatch)

    repository = ProjectRepository()
    project = repository.create_project(
        ProjectCreate(name="Registered", repo="owner/registered", branch="main", prd_path="docs/prd.md")
    )

    assert project.id == "owner__registered"
    assert project.progress_percent == 0
    assert project.total_tasks == 0
    assert repository.get_project("owner__registered") is not None
