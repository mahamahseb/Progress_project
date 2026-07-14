import os

from app.db.schema import init_db
from app.modules.sync.log_repository import sync_log_repository
from app.modules.sync.schema import SyncRequest
from app.modules.sync.service import sync_project_from_prd


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


def test_sync_uses_github_when_local_path_is_not_provided(monkeypatch) -> None:
    prepare_database(monkeypatch)

    def fake_fetch_file(self, *, repo, branch, path):
        assert repo == "owner/repo"
        assert branch == "main"
        assert path == "prd.md"
        return "# Project: Remote Demo\n\n## Work\n- [x] Done\n- [ ] Todo\n"

    monkeypatch.setattr("app.modules.github.client.GitHubClient.fetch_file", fake_fetch_file)

    project = sync_project_from_prd(
        SyncRequest(repo="owner/repo", branch="main", prd_path="prd.md")
    )

    assert project.id == "owner__repo"
    assert project.name == "Remote Demo"
    assert project.progress_percent == 50
    assert project.total_tasks == 2

    logs = sync_log_repository.list_logs(project_id="owner__repo")
    assert logs[0].status == "success"
    assert logs[0].message == "Synced 2 tasks at 50%"
