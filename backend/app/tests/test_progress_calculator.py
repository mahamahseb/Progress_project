from app.modules.progress.calculator import calculate_progress_percent
from app.parsers.types import ParsedTask


def test_calculate_weighted_progress() -> None:
    tasks = [
        ParsedTask(title="Done", section="General", is_completed=True, source_line=1, weight=3),
        ParsedTask(title="Todo", section="General", is_completed=False, source_line=2, weight=1),
    ]

    assert calculate_progress_percent(tasks) == 75


def test_empty_tasks_are_zero_percent() -> None:
    assert calculate_progress_percent([]) == 0
