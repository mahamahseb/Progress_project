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

This CI does not deploy to Minikube.

## GitHub Actions CD

The manual Minikube deployment workflow is defined in:

```txt
.github/workflows/deploy-minikube.yml
```

It runs only when triggered manually with `workflow_dispatch`.

Runner requirement:

```txt
self-hosted
linux
```

The self-hosted runner should be installed on the Minikube server so it can access:

- Docker
- Minikube
- kubectl
- the local Kubernetes cluster

The deployment workflow runs:

```bash
bash scripts/deploy-minikube.sh
```

It builds Docker images, loads them into Minikube, applies `k8s/progress-tracker.yaml`, and waits for backend/frontend rollout.

The workflow does not keep `kubectl port-forward` running forever. Start or manage port-forward separately:

```bash
kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller 8081:80
```

For a more permanent setup, create a systemd service for the port-forward or expose ingress through NodePort, LoadBalancer, or a reverse proxy.

## Self-Hosted Runner Setup

On the Minikube server, install a GitHub self-hosted runner from:

```txt
GitHub repo -> Settings -> Actions -> Runners -> New self-hosted runner
```

Choose Linux, then follow GitHub's generated commands on the server.

After setup, confirm the runner has these tools:

```bash
docker --version
minikube version
kubectl version --client
```

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
