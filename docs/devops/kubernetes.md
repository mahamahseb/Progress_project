# Kubernetes

## Overview

This project can be deployed to Minikube with:

- `k8s/progress-tracker.yaml`
- `progress-tracker-backend:latest`
- `progress-tracker-frontend:latest`

## Server

Example server from the Minikube reference document:

```bash
ssh mah@192.168.239.141
```

Check Minikube:

```bash
minikube status
kubectl get nodes -o wide
```

Start Minikube if needed:

```bash
minikube start
```

## Build Images

From the project root:

```bash
docker build -t progress-tracker-backend:latest -f backend/Dockerfile .
docker build -t progress-tracker-frontend:latest -f frontend/Dockerfile ./frontend
```

Load into Minikube:

```bash
minikube image load progress-tracker-backend:latest
minikube image load progress-tracker-frontend:latest
```

The frontend container uses:

- `API_BASE_URL` for server-side calls inside the cluster.
- `NEXT_PUBLIC_API_BASE_URL` for browser-side calls. In this ingress setup it is intentionally empty so browser requests use relative `/api` routes through the same host.

## Deploy

Enable ingress:

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

Or run the deployment helper from the project root on the Minikube server:

```bash
bash scripts/deploy-minikube.sh
```

Apply manifests:

```bash
kubectl apply -f k8s/progress-tracker.yaml
```

Wait for rollout:

```bash
kubectl rollout status deployment/progress-tracker-backend -n progress-tracker
kubectl rollout status deployment/progress-tracker-frontend -n progress-tracker
```

Check resources:

```bash
kubectl get pods -n progress-tracker -o wide
kubectl get svc -n progress-tracker
kubectl get ingress -n progress-tracker -o wide
kubectl get pvc -n progress-tracker
```

## Browser Access

Forward ingress controller to server port `8081`.

Use `8081` if another Minikube namespace/app is already exposed on `8080`:

```bash
kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller 8081:80
```

Run in background:

```bash
nohup kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller 8081:80 > /tmp/progress-tracker-ingress-port-forward.log 2>&1 &
```

Open:

```txt
http://192.168.239.141:8081/
```

Health check:

```bash
curl http://127.0.0.1:8081/health
```

## Common Commands

```bash
kubectl get ns
kubectl get pods -n progress-tracker
kubectl get pods -A
kubectl get deployment -n progress-tracker
kubectl get svc -n progress-tracker
kubectl get ingress -n progress-tracker
kubectl describe pod -n progress-tracker <pod-name>
kubectl logs -n progress-tracker <pod-name>
```

## Notes

- The backend stores SQLite data at `/data/progress_tracker.db`.
- The manifest creates a PVC named `progress-tracker-data`.
- `port-forward` is not permanent. Restart it after server reboot or process exit.
- For production-like usage, expose ingress through NodePort, LoadBalancer, or a reverse proxy instead of manual port-forward.
