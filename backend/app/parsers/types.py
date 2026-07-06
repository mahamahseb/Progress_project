from pydantic import BaseModel


class ParsedTask(BaseModel):
    title: str
    section: str
    is_completed: bool
    source_line: int
    weight: int = 1


class ParsedPrd(BaseModel):
    project_name: str
    tasks: list[ParsedTask]
