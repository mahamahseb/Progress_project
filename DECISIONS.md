# Architecture Decision Records

## ADR-001: Keep Backend and Frontend Separate

Status: accepted

The project keeps `backend/` and `frontend/` as top-level runtime folders so development commands remain simple and explicit.

## ADR-002: Use SQLite for MVP Persistence

Status: accepted

SQLite is used for the MVP to avoid operational overhead. The repository layer keeps migration to PostgreSQL practical later.

## ADR-003: Use PRD Markdown as Progress Source

Status: accepted

Progress is calculated from Markdown checkbox tasks in PRD files. Parser logic ignores fenced code blocks to avoid counting examples.
