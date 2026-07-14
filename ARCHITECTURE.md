# Architecture

## Overview

Project Progress Tracker is split into a FastAPI backend and a Next.js frontend.

```txt
GitHub Actions or manual sync
  -> FastAPI sync API
  -> GitHub/local PRD reader
  -> Markdown parser
  -> progress calculator
  -> PostgreSQL persistence
  -> dashboard API
  -> Next.js dashboard
```

## Runtime Components

- `backend/`: API, parser, GitHub integration, PostgreSQL persistence, tests.
- `frontend/`: dashboard UI, project registration form, project detail view, sync logs.
- `examples/`: sample tracked project PRD and GitHub Actions workflow.

## Detailed Docs

- Component diagram: `docs/architecture/component-diagram.md`
- Sequence diagram: `docs/architecture/sequence-diagram.md`
- Integration map: `docs/architecture/integration-map.md`
