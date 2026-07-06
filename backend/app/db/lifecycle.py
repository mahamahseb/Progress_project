from app.db.schema import init_db
from app.db.session import get_connection


def initialize_database() -> None:
    with get_connection() as connection:
        init_db(connection)
