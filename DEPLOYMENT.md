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
  -> https://progress-tracker.192.168.239.141.sslip.io
  -> https://progress-tracker.mah.com
  -> lab1:443
  -> socat forwarder
  -> minikube ingress: 192.168.49.2:443
  -> NGINX Ingress Controller
  -> Ingress: progress-tracker
  -> Service: progress-tracker-frontend
  -> Pods: frontend x 3, backend x 3
```

The shared NGINX Ingress Controller routes each namespace by hostname:

```txt
https://hello.192.168.239.141.sslip.io
https://hello.mah.com
  -> ingress-nginx
  -> namespace: hello-world
  -> ingress: hello-world

https://progress-tracker.192.168.239.141.sslip.io
https://progress-tracker.mah.com
  -> ingress-nginx
  -> namespace: progress-tracker
  -> ingress: progress-tracker
```

Direct port-forward fallback:

```txt
Browser
  -> http://<server-ip>:8081
  -> kubectl port-forward
  -> Service: progress-tracker-frontend
```

NodePort fallback:

```txt
Browser
  -> http://<server-ip>:30081
  -> Service: progress-tracker-web (NodePort)
  -> Service: progress-tracker-frontend
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
| Service | `progress-tracker-frontend` | `progress-tracker` | Internal frontend service |
| Service | `progress-tracker-web` | `progress-tracker` | NodePort access for `http://<server-ip>:30081` |
| Ingress | `progress-tracker` | `progress-tracker` | Routes `progress-tracker.192.168.239.141.sslip.io` and `progress-tracker.mah.com` HTTPS access to the frontend service |

## Images

### Local Minikube Images

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

### DockerHub Images

For the `dev -> GitHub -> DockerHub -> Minikube` flow, GitHub Actions builds and pushes:

```txt
<dockerhub-username>/progress-tracker-backend:<git-sha>
<dockerhub-username>/progress-tracker-frontend:<git-sha>
<dockerhub-username>/progress-tracker-backend:latest
<dockerhub-username>/progress-tracker-frontend:latest
```

Add these repository secrets in GitHub:

| Secret | Purpose |
|---|---|
| `DOCKERHUB_USERNAME` | DockerHub username or namespace |
| `DOCKERHUB_TOKEN` | DockerHub access token |

When `DOCKERHUB_NAMESPACE` is set, `scripts/deploy-minikube.sh` uses DockerHub images instead of building images on the Minikube server:

```bash
DOCKERHUB_NAMESPACE=<dockerhub-username> IMAGE_TAG=latest USE_REMOTE_IMAGES=1 bash scripts/deploy-minikube.sh
```

The deployment workflow automatically sets `DOCKERHUB_NAMESPACE` from `DOCKERHUB_USERNAME` and deploys the Git commit SHA image after CI succeeds.

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

For the DockerHub pipeline:

```txt
dev push to main
  -> GitHub Actions CI
  -> DockerHub publish
  -> Deploy to Minikube workflow
  -> Minikube pulls DockerHub images
```

Install the runner on the Minikube server:

```bash
git pull origin main
RUNNER_TOKEN=<token-from-github> bash scripts/install-github-runner.sh
```

Or run the steps manually:

```bash
minikube addons enable ingress
kubectl apply -f k8s/progress-tracker.yaml
kubectl rollout status deployment/progress-tracker-backend -n progress-tracker
kubectl rollout status deployment/progress-tracker-frontend -n progress-tracker
```

Open the dashboard through HTTPS ingress after deployment:

```txt
https://progress-tracker.192.168.239.141.sslip.io/
https://progress-tracker.mah.com/
```

This `sslip.io` hostname resolves to `192.168.239.141`, so no local hosts-file edit is required.
The `mah.com` lab hostname must resolve through lab1 BIND DNS or a local hosts-file entry to `192.168.239.141`.

The deployment script moves the existing `hello-world` ingress to `hello.192.168.239.141.sslip.io` and `hello.mah.com`, creates a self-signed TLS certificate for both Progress Tracker hostnames, configures the Ingress TLS secret, and expects server port `443` to forward to the NGINX Ingress Controller through the lab1 ingress forwarding service.

Because this is a self-signed certificate, the browser may show a certificate warning until the certificate is trusted on the client machine.

If the GitHub Actions runner cannot bind port `443` because sudo requires a password, run this on the Minikube server:

```bash
sudo kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller 443:443
```

For persistent HTTPS access on the Minikube server, install the systemd service:

```bash
bash scripts/install-ingress-https-service.sh
```

If the runner cannot bind `443`, the deployment script falls back to `8443`:

```txt
https://progress-tracker.192.168.239.141.sslip.io:8443/
```

In the current lab1 architecture, the preferred persistent path is `lab1:443 -> socat -> minikube ingress 192.168.49.2:443`, not the fallback `8443` path.

Test:

```bash
curl -kI https://127.0.0.1/
curl -kI https://progress-tracker.192.168.239.141.sslip.io/
curl -kI https://progress-tracker.mah.com/
```

Direct port-forward fallback:

```txt
http://192.168.239.141:8081/
```

If direct port-forward is unavailable, use the NodePort fallback:

```txt
http://192.168.239.141:30081/
```

## Future Production Direction

- PostgreSQL instead of SQLite.
- Managed ingress or reverse proxy instead of long-running `port-forward`.
- Secret management for GitHub token and sync token.
- CI/CD image build and deployment pipeline.
