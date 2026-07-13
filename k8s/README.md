# Kubernetes Manifests

This folder contains application-owned Kubernetes manifests for Progress Tracker.

## App Layer

`progress-tracker.yaml` owns these resources:

- Namespace: `progress-tracker`
- Secret: `progress-tracker-secrets`
- PVC: `progress-tracker-data`
- Deployments: backend and frontend
- Services: backend, frontend, and NodePort fallback
- Ingress: `progress-tracker`

Apply this layer on the Minikube server:

```bash
kubectl apply -f k8s/progress-tracker.yaml
```

## Shared Infra Layer

Do not put shared lab/server setup in this app manifest. These are owned by the
infra layer:

- Minikube installation and lifecycle
- NGINX Ingress Controller installation
- `lab1:80` and `lab1:443` forwarding
- DNS records for `*.mah.com`
- Firewall rules
- Shared storage policy

For the shared Minikube architecture checklist, see `updateMinikube.md`.
