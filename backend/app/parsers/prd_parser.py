import re

from app.parsers.types import ParsedPrd, ParsedTask

PROJECT_RE = re.compile(r"^#\s+(?:Project:\s*)?(?P<name>.+?)\s*$", re.IGNORECASE)
HEADING_RE = re.compile(r"^(#{2,6})\s+(?P<section>.+?)\s*$")
TASK_RE = re.compile(r"^\s*[-*]\s+\[(?P<mark>[ xX])\]\s+(?P<title>.+?)\s*$")
WEIGHT_RE = re.compile(r"<!--\s*weight:\s*(?P<weight>\d+)\s*-->", re.IGNORECASE)


def parse_prd_markdown(markdown: str, fallback_project_name: str = "Untitled Project") -> ParsedPrd:
    project_name = fallback_project_name
    current_section = "General"
    is_inside_fenced_code = False
    tasks: list[ParsedTask] = []

    for index, line in enumerate(markdown.splitlines(), start=1):
        if line.strip().startswith("```"):
            is_inside_fenced_code = not is_inside_fenced_code
            continue

        if is_inside_fenced_code:
            continue

        project_match = PROJECT_RE.match(line)
        if project_match and project_name == fallback_project_name:
            project_name = project_match.group("name").strip()
            continue

        heading_match = HEADING_RE.match(line)
        if heading_match:
            current_section = heading_match.group("section").strip()
            continue

        task_match = TASK_RE.match(line)
        if not task_match:
            continue

        raw_title = task_match.group("title").strip()
        weight_match = WEIGHT_RE.search(raw_title)
        weight = int(weight_match.group("weight")) if weight_match else 1
        title = WEIGHT_RE.sub("", raw_title).strip()

        tasks.append(
            ParsedTask(
                title=title,
                section=current_section,
                is_completed=task_match.group("mark").lower() == "x",
                source_line=index,
                weight=weight,
            )
        )

    return ParsedPrd(project_name=project_name, tasks=tasks)
