# Deployment Architecture

## MVP Runtime

- Backend: FastAPI served by Uvicorn on port `8000`.
- Frontend: Next.js served on port `3000`.
- Database: SQLite for local/MVP use.
- Sync source: GitHub raw PRD files or local sample PRD files.

## Local Docker

Backend Docker support:

- `backend/Dockerfile`
- `docker-compose.yml`

Frontend Docker support:

- `frontend/Dockerfile`

## Minikube Deployment

The Minikube deployment uses:

```txt
Browser
  -> http://<server-ip>:8081
  -> kubectl port-forward
  -> Service: progress-tracker-frontend
  -> Pods: frontend x 3, backend x 3
```

Resource summary:

| Resource | Name | Namespace | Purpose |
|---|---|---|---|
| Namespace | `progress-tracker` | - | Isolates app resources |
| Secret | `progress-tracker-secrets` | `progress-tracker` | Stores `SYNC_TOKEN` and optional `GITHUB_TOKEN` |
| PVC | `progress-tracker-data` | `progress-tracker` | Stores SQLite database |
| Deployment | `progress-tracker-backend` | `progress-tracker` | Runs FastAPI backend |
| Deployment | `progress-tracker-frontend` | `progress-tracker` | Runs Next.js frontend |
| Service | `progress-tracker-backend` | `progress-tracker` | Internal backend service |
| Service | `progress-tracker-frontend` | `progress-tracker` | Internal frontend service exposed through port-forward |

## Images

Build images locally:

```bash
docker build -t progress-tracker-backend:latest -f backend/Dockerfile .
docker build -t progress-tracker-frontend:latest -f frontend/Dockerfile ./frontend
```

Load images into Minikube:

```bash
minikube image load progress-tracker-backend:latest
minikube image load progress-tracker-frontend:latest
```

The Kubernetes manifest uses:

```yaml
imagePullPolicy: Never
```

because the images are loaded into Minikube directly.

The frontend uses two API base settings:

- `API_BASE_URL`: internal backend URL for server-side rendering.
- `NEXT_PUBLIC_API_BASE_URL`: browser-side URL. In the Minikube setup this is empty so browser requests use relative `/api` routes.

Next.js rewrites `/api/*` and `/health` to the backend service inside the cluster, so the browser only needs one exposed port.

## Deploy

From the project root on the Minikube server, run:

```bash
bash scripts/deploy-minikube.sh
```

Or run the manual GitHub Actions deployment workflow:

```txt
Actions -> Deploy to Minikube -> Run workflow
```

This requires a self-hosted Linux runner on the Minikube server.

Install the runner on the Minikube server:

```bash
git pull origin main
RUNNER_TOKEN=<token-from-github> bash scripts/install-github-runner.sh
```

Or run the steps manually:

```bash
kubectl apply -f k8s/progress-tracker.yaml
kubectl rollout status deployment/progress-tracker-backend -n progress-tracker
kubectl rollout status deployment/progress-tracker-frontend -n progress-tracker
```

Expose the frontend service on server port `8081`.

Use `8081` to avoid conflicts with an existing Minikube app or namespace that may already be using `8080`:

```bash
kubectl -n progress-tracker port-forward --address 0.0.0.0 svc/progress-tracker-frontend 8081:3000
```

Test:

```bash
curl http://127.0.0.1:8081/health
```

Open dashboard:

```txt
http://<server-ip>:8081/
```

## Future Production Direction

- PostgreSQL instead of SQLite.
- Managed ingress or reverse proxy instead of long-running `port-forward`.
- Secret management for GitHub token and sync token.
- CI/CD image build and deployment pipeline.
