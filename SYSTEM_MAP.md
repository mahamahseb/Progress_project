# System Map

## Systems

- Progress Tracker Backend: receives sync requests, parses PRD files, stores progress.
- Progress Tracker Frontend: displays project progress and sync activity.
- GitHub: stores project repositories and PRD files.
- GitHub Actions: notifies the backend after pushes.
- SQLite: stores projects, parsed tasks, and sync logs for the MVP.

## Main Integration Points

- `POST /api/sync/github`
- GitHub raw file URL
- Next.js API calls to the backend
