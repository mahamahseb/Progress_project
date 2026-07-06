#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="progress-tracker"
BACKEND_IMAGE="progress-tracker-backend:latest"
FRONTEND_IMAGE="progress-tracker-frontend:latest"
PORT_FORWARD_PORT="${PORT_FORWARD_PORT:-8081}"
PORT_FORWARD_LOG="/tmp/progress-tracker-port-forward.log"

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

echo "Restarting deployments to use the latest loaded images..."
kubectl rollout restart deployment/progress-tracker-backend -n "${NAMESPACE}"
kubectl rollout restart deployment/progress-tracker-frontend -n "${NAMESPACE}"

echo "Waiting for rollout..."
kubectl rollout status deployment/progress-tracker-backend -n "${NAMESPACE}"
kubectl rollout status deployment/progress-tracker-frontend -n "${NAMESPACE}"

echo "Current resources:"
kubectl get pods -n "${NAMESPACE}" -o wide
kubectl get svc -n "${NAMESPACE}"
kubectl get ingress -n "${NAMESPACE}" -o wide
kubectl get pvc -n "${NAMESPACE}"

echo "Starting direct IP port-forward on port ${PORT_FORWARD_PORT}..."
existing_pids="$(pgrep -f "[k]ubectl -n ${NAMESPACE} port-forward --address 0.0.0.0 svc/progress-tracker-frontend ${PORT_FORWARD_PORT}:3000" || true)"
if [ -n "${existing_pids}" ]; then
  kill ${existing_pids} || true
  sleep 2
fi

if command -v setsid >/dev/null 2>&1; then
  env -u RUNNER_TRACKING_ID setsid nohup kubectl -n "${NAMESPACE}" port-forward --address 0.0.0.0 svc/progress-tracker-frontend "${PORT_FORWARD_PORT}:3000" > "${PORT_FORWARD_LOG}" 2>&1 < /dev/null &
else
  env -u RUNNER_TRACKING_ID nohup kubectl -n "${NAMESPACE}" port-forward --address 0.0.0.0 svc/progress-tracker-frontend "${PORT_FORWARD_PORT}:3000" > "${PORT_FORWARD_LOG}" 2>&1 < /dev/null &
fi

for attempt in 1 2 3 4 5; do
  sleep 2
  if curl -fsS "http://127.0.0.1:${PORT_FORWARD_PORT}/" >/dev/null; then
    break
  fi
  if [ "${attempt}" = "5" ]; then
    echo "Port-forward did not become ready on 127.0.0.1:${PORT_FORWARD_PORT}"
    cat "${PORT_FORWARD_LOG}" || true
    exit 1
  fi
done

echo "Port-forward status:"
pgrep -af "[k]ubectl -n ${NAMESPACE} port-forward --address 0.0.0.0 svc/progress-tracker-frontend ${PORT_FORWARD_PORT}:3000" || true
cat "${PORT_FORWARD_LOG}" || true

echo "Opening firewall ports when non-interactive sudo is available..."
if command -v ufw >/dev/null 2>&1; then
  if sudo -n true >/dev/null 2>&1; then
    sudo ufw allow "${PORT_FORWARD_PORT}/tcp" || true
    sudo ufw allow 30081/tcp || true
    sudo ufw status || true
  else
    echo "Skipping ufw update because sudo requires a password."
    echo "Run manually on the Minikube server:"
    echo "sudo ufw allow ${PORT_FORWARD_PORT}/tcp"
    echo "sudo ufw allow 30081/tcp"
  fi
else
  echo "ufw is not installed; skipping firewall update."
fi

echo "Listening ports:"
ss -ltnp | grep -E ":(${PORT_FORWARD_PORT}|30081) " || true

echo "Local access checks:"
curl -I --max-time 5 "http://127.0.0.1:${PORT_FORWARD_PORT}/" || true
curl -I --max-time 5 "http://192.168.239.141:${PORT_FORWARD_PORT}/" || true

cat <<EOF

Deployment applied.

Direct IP access:

http://<server-ip>:${PORT_FORWARD_PORT}/

Current server URL:

http://192.168.239.141:${PORT_FORWARD_PORT}/

NodePort fallback:

http://<server-ip>:30081/

Ingress host:

progress-tracker.local

Direct health check:

curl http://127.0.0.1:${PORT_FORWARD_PORT}/health
EOF
