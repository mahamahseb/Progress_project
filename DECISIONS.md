# Architecture Decision Records

## ADR-001: Keep Backend and Frontend Separate

Status: accepted

The project keeps `backend/` and `frontend/` as top-level runtime folders so development commands remain simple and explicit.

## ADR-002: Use PostgreSQL for Runtime Persistence

Status: accepted

PostgreSQL is used for runtime persistence so the backend can run multiple replicas and keep data in a shared database service.

## ADR-003: Use PRD Markdown as Progress Source

Status: accepted

Progress is calculated from Markdown checkbox tasks in PRD files. Parser logic ignores fenced code blocks to avoid counting examples.
