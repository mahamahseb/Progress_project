from sqlite3 import Connection


def init_db(connection: Connection) -> None:
    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            repo TEXT NOT NULL,
            branch TEXT NOT NULL,
            prd_path TEXT NOT NULL,
            progress_percent INTEGER NOT NULL,
            total_tasks INTEGER NOT NULL,
            completed_tasks INTEGER NOT NULL,
            last_commit_sha TEXT,
            last_synced_at TEXT
        );

        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id TEXT NOT NULL,
            title TEXT NOT NULL,
            section TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            source_line INTEGER NOT NULL,
            weight INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);

        CREATE TABLE IF NOT EXISTS sync_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id TEXT NOT NULL,
            repo TEXT NOT NULL,
            commit_sha TEXT,
            status TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_sync_logs_project_id ON sync_logs(project_id);
        """
    )
    connection.commit()
