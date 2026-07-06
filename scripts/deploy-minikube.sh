#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="progress-tracker"
BACKEND_IMAGE="progress-tracker-backend:latest"
FRONTEND_IMAGE="progress-tracker-frontend:latest"
PORT_FORWARD_PORT="${PORT_FORWARD_PORT:-8081}"

echo "Checking Minikube..."
minikube status
kubectl get nodes -o wide

echo "Building Docker images..."
docker build -t "${BACKEND_IMAGE}" -f backend/Dockerfile .
docker build -t "${FRONTEND_IMAGE}" -f frontend/Dockerfile ./frontend

echo "Loading images into Minikube..."
minikube image load "${BACKEND_IMAGE}"
minikube image load "${FRONTEND_IMAGE}"

echo "Enabling ingress..."
minikube addons enable ingress
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/progress-tracker.yaml

echo "Waiting for rollout..."
kubectl rollout status deployment/progress-tracker-backend -n "${NAMESPACE}"
kubectl rollout status deployment/progress-tracker-frontend -n "${NAMESPACE}"

echo "Current resources:"
kubectl get pods -n "${NAMESPACE}" -o wide
kubectl get svc -n "${NAMESPACE}"
kubectl get ingress -n "${NAMESPACE}" -o wide
kubectl get pvc -n "${NAMESPACE}"

cat <<EOF

Deployment applied.

To expose through ingress-nginx on port ${PORT_FORWARD_PORT}, run:

kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller ${PORT_FORWARD_PORT}:80

Then open:

http://<server-ip>:${PORT_FORWARD_PORT}/

Health check:

curl http://127.0.0.1:${PORT_FORWARD_PORT}/health
EOF
