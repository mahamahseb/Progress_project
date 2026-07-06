from datetime import UTC, datetime

from app.db.schema import init_db
from app.db.session import get_connection
from app.modules.projects.schema import ProjectCreate, ProjectDetail, TaskRead


class ProjectRepository:
    def __init__(self) -> None:
        with get_connection() as connection:
            init_db(connection)

    def list_projects(self) -> list[ProjectDetail]:
        with get_connection() as connection:
            rows = connection.execute(
                """
                SELECT *
                FROM projects
                ORDER BY last_synced_at DESC, name ASC
                """
            ).fetchall()
            return [self._project_from_row(row, tasks=[]) for row in rows]

    def get_project(self, project_id: str) -> ProjectDetail | None:
        with get_connection() as connection:
            project_row = connection.execute(
                "SELECT * FROM projects WHERE id = ?",
                (project_id,),
            ).fetchone()
            if project_row is None:
                return None

            task_rows = connection.execute(
                """
                SELECT title, section, is_completed, source_line, weight
                FROM tasks
                WHERE project_id = ?
                ORDER BY source_line ASC
                """,
                (project_id,),
            ).fetchall()

        tasks = [
            TaskRead(
                title=row["title"],
                section=row["section"],
                is_completed=bool(row["is_completed"]),
                source_line=row["source_line"],
                weight=row["weight"],
            )
            for row in task_rows
        ]
        return self._project_from_row(project_row, tasks=tasks)

    def create_project(self, payload: ProjectCreate) -> ProjectDetail:
        project_id = payload.project_id or payload.repo.replace("/", "__")
        last_synced_at = datetime.now(UTC)

        with get_connection() as connection:
            connection.execute(
                """
                INSERT INTO projects (
                    id,
                    name,
                    repo,
                    branch,
                    prd_path,
                    progress_percent,
                    total_tasks,
                    completed_tasks,
                    last_commit_sha,
                    last_synced_at
                )
                VALUES (?, ?, ?, ?, ?, 0, 0, 0, NULL, ?)
                """,
                (
                    project_id,
                    payload.name,
                    payload.repo,
                    payload.branch,
                    payload.prd_path,
                    last_synced_at.isoformat(),
                ),
            )
            connection.commit()

        return ProjectDetail(
            id=project_id,
            name=payload.name,
            repo=payload.repo,
            branch=payload.branch,
            prd_path=payload.prd_path,
            progress_percent=0,
            total_tasks=0,
            completed_tasks=0,
            last_commit_sha=None,
            last_synced_at=last_synced_at,
            tasks=[],
        )

    def upsert_project(
        self,
        *,
        project_id: str,
        name: str,
        repo: str,
        branch: str,
        prd_path: str,
        progress_percent: int,
        tasks: list[TaskRead],
        last_commit_sha: str | None,
    ) -> ProjectDetail:
        completed_tasks = sum(1 for task in tasks if task.is_completed)
        last_synced_at = datetime.now(UTC)

        with get_connection() as connection:
            connection.execute(
                """
                INSERT INTO projects (
                    id,
                    name,
                    repo,
                    branch,
                    prd_path,
                    progress_percent,
                    total_tasks,
                    completed_tasks,
                    last_commit_sha,
                    last_synced_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    repo = excluded.repo,
                    branch = excluded.branch,
                    prd_path = excluded.prd_path,
                    progress_percent = excluded.progress_percent,
                    total_tasks = excluded.total_tasks,
                    completed_tasks = excluded.completed_tasks,
                    last_commit_sha = excluded.last_commit_sha,
                    last_synced_at = excluded.last_synced_at
                """,
                (
                    project_id,
                    name,
                    repo,
                    branch,
                    prd_path,
                    progress_percent,
                    len(tasks),
                    completed_tasks,
                    last_commit_sha,
                    last_synced_at.isoformat(),
                ),
            )
            connection.execute("DELETE FROM tasks WHERE project_id = ?", (project_id,))
            connection.executemany(
                """
                INSERT INTO tasks (
                    project_id,
                    title,
                    section,
                    is_completed,
                    source_line,
                    weight
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                [
                    (
                        project_id,
                        task.title,
                        task.section,
                        int(task.is_completed),
                        task.source_line,
                        task.weight,
                    )
                    for task in tasks
                ],
            )
            connection.commit()

        return ProjectDetail(
            id=project_id,
            name=name,
            repo=repo,
            branch=branch,
            prd_path=prd_path,
            progress_percent=progress_percent,
            total_tasks=len(tasks),
            completed_tasks=completed_tasks,
            last_commit_sha=last_commit_sha,
            last_synced_at=last_synced_at,
            tasks=tasks,
        )

    def _project_from_row(self, row, *, tasks: list[TaskRead]) -> ProjectDetail:
        last_synced_at = row["last_synced_at"]
        return ProjectDetail(
            id=row["id"],
            name=row["name"],
            repo=row["repo"],
            branch=row["branch"],
            prd_path=row["prd_path"],
            progress_percent=row["progress_percent"],
            total_tasks=row["total_tasks"],
            completed_tasks=row["completed_tasks"],
            last_commit_sha=row["last_commit_sha"],
            last_synced_at=datetime.fromisoformat(last_synced_at) if last_synced_at else None,
            tasks=tasks,
        )


project_repository = ProjectRepository()
