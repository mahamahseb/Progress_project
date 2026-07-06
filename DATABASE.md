# Database Overview

## MVP Database

The MVP uses SQLite.

Default path:

```txt
backend/progress_tracker.db
```

## Tables

- `projects`: tracked project summary and latest progress.
- `tasks`: parsed PRD tasks for each project.
- `sync_logs`: sync attempt history.

## Schema Source

See `backend/app/db/schema.py`.
