# CI/CD

Future CI should run:

- Backend tests.
- Frontend build.
- Optional Docker build.

## GitHub Actions Sync

Tracked repositories can call:

```http
POST /api/sync/github
Authorization: Bearer <PROGRESS_TRACKER_TOKEN>
```

Required repository secrets:

```txt
PROGRESS_TRACKER_URL=https://your-progress-tracker.example.com
PROGRESS_TRACKER_TOKEN=your-secret-token
```

The token must match backend `SYNC_TOKEN`.
