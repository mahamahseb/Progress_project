import sqlite3
from pathlib import Path

from app.core.config import settings


def get_connection() -> sqlite3.Connection:
    db_path = Path(settings.database_path)
    if db_path.parent != Path("."):
        db_path.parent.mkdir(parents=True, exist_ok=True)

    connection = sqlite3.connect(db_path)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection
