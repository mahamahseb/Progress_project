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

## Shared Infra Prerequisite

The lab/server layer owns Minikube, the NGINX Ingress Controller, DNS, firewall
rules, and the stable `lab1:80/443` forwarding services.

Check the shared ingress layer:

```bash
kubectl get pods -n ingress-nginx
systemctl status lab1-ingress-80.service lab1-ingress-443.service --no-pager
ss -ltnp | grep -E ':80|:443'
```

See `infra/lab1/README.md` for the shared infrastructure setup.

## Deploy

Run the application deployment helper from the project root on the Minikube server:

```bash
bash scripts/deploy-minikube.sh
```

Apply manifests:

```bash
kubectl apply -f k8s/progress-tracker.yaml
```

Wait for rollout:

```bash
kubectl rollout status deployment/progress-tracker-postgres -n progress-tracker
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

Open:

```txt
https://progress-tracker.192.168.239.141.sslip.io/
https://progress-tracker.mah.com/
```

Health check:

```bash
curl -kI https://progress-tracker.192.168.239.141.sslip.io/
curl -kI https://progress-tracker.mah.com/
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

- PostgreSQL stores data in the `progress-tracker-postgres-data` PVC.
- The backend connects with `DATABASE_URL` from `progress-tracker-secrets`.
- Persistent access should use the shared lab1 ingress services, not manual `kubectl port-forward`.
- NodePort and direct port-forward are fallback paths only.
