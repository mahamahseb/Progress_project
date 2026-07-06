from app.parsers.types import ParsedTask


def calculate_progress_percent(tasks: list[ParsedTask]) -> int:
    total_weight = sum(task.weight for task in tasks)
    if total_weight == 0:
        return 0

    completed_weight = sum(task.weight for task in tasks if task.is_completed)
    return round((completed_weight / total_weight) * 100)
