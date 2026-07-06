from datetime import UTC, datetime

from app.db.schema import init_db
from app.db.session import get_connection
from app.modules.sync.schema import SyncLogRead


class SyncLogRepository:
    def __init__(self) -> None:
        with get_connection() as connection:
            init_db(connection)

    def create_log(
        self,
        *,
        project_id: str,
        repo: str,
        commit_sha: str | None,
        status: str,
        message: str,
    ) -> SyncLogRead:
        created_at = datetime.now(UTC)
        with get_connection() as connection:
            cursor = connection.execute(
                """
                INSERT INTO sync_logs (
                    project_id,
                    repo,
                    commit_sha,
                    status,
                    message,
                    created_at
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (project_id, repo, commit_sha, status, message, created_at.isoformat()),
            )
            connection.commit()
            log_id = cursor.lastrowid

        return SyncLogRead(
            id=log_id,
            project_id=project_id,
            repo=repo,
            commit_sha=commit_sha,
            status=status,
            message=message,
            created_at=created_at,
        )

    def list_logs(self, project_id: str | None = None, limit: int = 50) -> list[SyncLogRead]:
        sql = """
            SELECT id, project_id, repo, commit_sha, status, message, created_at
            FROM sync_logs
        """
        params: list[object] = []
        if project_id:
            sql += " WHERE project_id = ?"
            params.append(project_id)
        sql += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)

        with get_connection() as connection:
            rows = connection.execute(sql, params).fetchall()

        return [
            SyncLogRead(
                id=row["id"],
                project_id=row["project_id"],
                repo=row["repo"],
                commit_sha=row["commit_sha"],
                status=row["status"],
                message=row["message"],
                created_at=datetime.fromisoformat(row["created_at"]),
            )
            for row in rows
        ]


sync_log_repository = SyncLogRepository()
