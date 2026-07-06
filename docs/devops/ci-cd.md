# CI/CD

Future CI should run:

- Backend tests.
- Frontend build.
- Kubernetes manifest validation.
- Docker image build without pushing.

## GitHub Actions CI

The CI workflow is defined in:

```txt
.github/workflows/ci.yml
```

It runs on pushes and pull requests targeting `main`.

Jobs:

- `backend-tests`: installs FastAPI backend dependencies and runs `pytest`.
- `frontend-build`: installs frontend dependencies with `npm ci` and runs `npm run build`.
- `kubernetes-validate`: validates `k8s/progress-tracker.yaml` with `kubectl --dry-run=client`.
- `docker-build`: builds backend and frontend Docker images without pushing.

This CI does not deploy to Minikube yet. CD should be added later with a self-hosted runner on the Minikube server.

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
