# AGENTS.md

## Project

Project Progress Tracker is a web dashboard that tracks project development progress from `prd.md` files.

## Source of Truth

- `prd.md` is the source of truth for product scope, tasks, and progress percentage.
- Update `prd.md` checkbox status after completing work.
- Do not count or add progress tasks inside fenced code blocks.
- Keep `Out of Scope` items as normal bullets, not checkbox tasks, unless they become active work.

## Structure

```txt
backend/     FastAPI backend, parser, sync flow, SQLite persistence
frontend/    Next.js dashboard
docs/        Architecture and setup notes
examples/    Sample project PRD and GitHub Actions workflow
prd.md       Product requirements and progress checklist
```

## Backend Rules

- Keep Markdown parsing in `backend/app/parsers/prd_parser.py`.
- Keep progress calculation in `backend/app/modules/progress/calculator.py`.
- Keep GitHub fetching in `backend/app/modules/github/client.py`.
- Keep project persistence in `backend/app/modules/projects/repository.py`.
- Keep sync log persistence in `backend/app/modules/sync/log_repository.py`.
- API route files should stay thin and call repository/service code.

## Frontend Rules

- Keep project UI under `frontend/src/features/projects`.
- Use `frontend/src/shared/api/client.ts` for shared API configuration.
- Dashboard entry is `frontend/src/app/page.tsx`.
- Project detail entry is `frontend/src/app/projects/[id]/page.tsx`.
- Keep UI practical and dashboard-focused.

## Backend Commands

Run backend:

```powershell
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Run tests:

```powershell
cd backend
python -m pytest
```

If Windows temp permissions fail:

```powershell
cd backend
$env:TEMP=(Resolve-Path ..).Path + '\.tmp'
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Force -Path $env:TEMP | Out-Null
python -m pytest -p no:cacheprovider --basetemp ..\.pytest-tmp
```

## Frontend Commands

Run frontend:

```powershell
cd frontend
$env:NEXT_PUBLIC_API_BASE_URL='http://127.0.0.1:8000'
npm run dev
```

Build frontend:

```powershell
cd frontend
npm run build
```

If `npm run build` fails because Node cannot access a Windows user directory, use the bundled Node executable and run Next directly:

```powershell
cd frontend
C:\Users\Lenovo\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe .\node_modules\next\dist\bin\next build
```

## Environment

Backend `.env` supports:

```txt
APP_NAME=Project Progress Tracker
SYNC_TOKEN=change-me
GITHUB_TOKEN=
SAMPLE_PRD_PATH=../examples/sample-project/prd.md
DATABASE_PATH=progress_tracker.db
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

Frontend `.env` supports:

```txt
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
```

## Git Hygiene

Do not commit:

- `.env`
- `*.db`
- `.next/`
- `node_modules/`
- `.pytest_cache/`
- `.pytest-tmp/`
- `.npm-cache/`
- `.pnpm-store/`

## Completion Checklist

Before ending a substantial change:

- Run backend tests.
- Build frontend when UI or frontend API code changes.
- Update `prd.md` task checkboxes.
- Summarize any commands that failed because of local permission or environment issues.
