from collections.abc import Sequence
from typing import Any

import psycopg
from psycopg.rows import dict_row

from app.core.config import settings


def _convert_placeholders(sql: str) -> str:
    return sql.replace("?", "%s")


class DatabaseCursor:
    def __init__(self, cursor: psycopg.Cursor) -> None:
        self._cursor = cursor

    def fetchone(self) -> dict[str, Any] | None:
        return self._cursor.fetchone()

    def fetchall(self) -> list[dict[str, Any]]:
        return self._cursor.fetchall()


class DatabaseConnection:
    def __init__(self, connection: psycopg.Connection) -> None:
        self._connection = connection

    def __enter__(self) -> "DatabaseConnection":
        self._connection.__enter__()
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> None:
        self._connection.__exit__(exc_type, exc_value, traceback)

    def execute(self, sql: str, params: Sequence[Any] | None = None) -> DatabaseCursor:
        cursor = self._connection.execute(_convert_placeholders(sql), params)
        return DatabaseCursor(cursor)

    def executemany(self, sql: str, params_seq: Sequence[Sequence[Any]]) -> None:
        with self._connection.cursor() as cursor:
            cursor.executemany(_convert_placeholders(sql), params_seq)

    def commit(self) -> None:
        self._connection.commit()


def get_connection() -> DatabaseConnection:
    connection = psycopg.connect(settings.database_url, row_factory=dict_row)
    return DatabaseConnection(connection)
