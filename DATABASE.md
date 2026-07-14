# Database Overview

## Runtime Database

The application uses PostgreSQL.

Default connection URL:

```txt
postgresql://progress_tracker:progress_tracker@localhost:5432/progress_tracker
```

## Tables

- `projects`: tracked project summary and latest progress.
- `tasks`: parsed PRD tasks for each project.
- `sync_logs`: sync attempt history.

## Schema Source

See `backend/app/db/schema.py`.
