# Domain Model

## Entities

- Project: a tracked repository with a PRD path and progress state.
- Task: a checkbox item parsed from a PRD file.
- Sync Log: a record of a sync attempt.
- PRD: a Markdown document that defines scope and progress tasks.

## Relationships

- A project has many tasks.
- A project has many sync logs.
- A sync request updates one project.
