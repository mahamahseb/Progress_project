from app.db.schema import init_db
from app.modules.sync.log_repository import sync_log_repository
from app.modules.sync.schema import SyncRequest
from app.modules.sync.service import sync_project_from_prd


def test_sync_uses_github_when_local_path_is_not_provided(tmp_path, monkeypatch) -> None:
    db_path = tmp_path / "test.db"
    monkeypatch.setattr("app.core.config.settings.database_path", str(db_path))

    from app.db import session

    with session.get_connection() as connection:
        init_db(connection)

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
