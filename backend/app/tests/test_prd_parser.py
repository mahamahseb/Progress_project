from app.parsers.prd_parser import parse_prd_markdown


def test_parse_tasks_with_sections_and_weights() -> None:
    markdown = """# Project: CRM

## Backend
- [x] Create API <!-- weight: 3 -->
- [ ] Add tests
"""

    parsed = parse_prd_markdown(markdown)

    assert parsed.project_name == "CRM"
    assert len(parsed.tasks) == 2
    assert parsed.tasks[0].section == "Backend"
    assert parsed.tasks[0].is_completed is True
    assert parsed.tasks[0].weight == 3
    assert parsed.tasks[1].is_completed is False


def test_parse_ignores_tasks_inside_fenced_code_blocks() -> None:
    markdown = """# Project: Docs

```md
- [x] Example done task
- [ ] Example pending task
```

## Real Tasks
- [x] Real task
"""

    parsed = parse_prd_markdown(markdown)

    assert len(parsed.tasks) == 1
    assert parsed.tasks[0].title == "Real task"
