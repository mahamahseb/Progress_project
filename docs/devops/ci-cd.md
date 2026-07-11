# CI/CD

CI runs:

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

It runs when CI on `main` succeeds, and it can also be triggered manually with
`workflow_dispatch`.

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

It pulls the DockerHub images for the target Git commit, applies
`k8s/progress-tracker.yaml`, points the Deployments at those images, and waits
for backend/frontend rollout.

Persistent HTTP/HTTPS access is owned by the shared lab1 infrastructure layer:

```txt
lab1:80  -> socat -> minikube ingress 192.168.49.2:80
lab1:443 -> socat -> minikube ingress 192.168.49.2:443
```

The app deployment workflow should not create or manage those shared services.

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

This repository also provides an installer script:

```bash
git pull origin main
RUNNER_TOKEN=<token-from-github> bash scripts/install-github-runner.sh
```

Default runner settings:

```txt
REPO_URL=https://github.com/mahamahseb/Progress_project
RUNNER_NAME=progress-tracker-minikube
RUNNER_LABELS=self-hosted,linux,progress-tracker,minikube
RUNNER_DIR=$HOME/actions-runner-progress-tracker
```

You can override them:

```bash
RUNNER_TOKEN=<token> \
RUNNER_NAME=my-runner \
RUNNER_LABELS=self-hosted,linux,minikube \
bash scripts/install-github-runner.sh
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
