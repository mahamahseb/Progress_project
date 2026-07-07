#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="progress-tracker"
BACKEND_IMAGE="progress-tracker-backend:latest"
FRONTEND_IMAGE="progress-tracker-frontend:latest"
PORT_FORWARD_PORT="${PORT_FORWARD_PORT:-8081}"
PORT_FORWARD_LOG="/tmp/progress-tracker-port-forward.log"
SERVER_IP="${SERVER_IP:-192.168.239.141}"
HTTPS_PORT="${HTTPS_PORT:-443}"
HTTPS_FORWARD_LOG="/tmp/progress-tracker-https-port-forward.log"

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

echo "Preparing TLS certificate for https://${SERVER_IP}..."
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/progress-tracker-tls.key \
  -out /tmp/progress-tracker-tls.crt \
  -subj "/CN=${SERVER_IP}" \
  -addext "subjectAltName = IP:${SERVER_IP}"
kubectl create secret tls progress-tracker-tls \
  -n "${NAMESPACE}" \
  --cert=/tmp/progress-tracker-tls.crt \
  --key=/tmp/progress-tracker-tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

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

echo "Starting HTTPS ingress access on port ${HTTPS_PORT}..."
existing_https_pids="$(pgrep -f "[k]ubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller ${HTTPS_PORT}:443" || true)"
if [ -n "${existing_https_pids}" ]; then
  kill ${existing_https_pids} || true
  sleep 2
fi

if [ "${HTTPS_PORT}" = "443" ] && ! sudo -n true >/dev/null 2>&1; then
  echo "Cannot bind port 443 because sudo requires a password."
  echo "Run manually on the Minikube server:"
  echo "sudo kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller 443:443"
else
  if [ "${HTTPS_PORT}" = "443" ]; then
    HTTPS_FORWARD_CMD=(sudo -E env "KUBECONFIG=${KUBECONFIG:-$HOME/.kube/config}" kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller "${HTTPS_PORT}:443")
  else
    HTTPS_FORWARD_CMD=(kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller "${HTTPS_PORT}:443")
  fi

  if command -v setsid >/dev/null 2>&1; then
    env -u RUNNER_TRACKING_ID setsid nohup "${HTTPS_FORWARD_CMD[@]}" > "${HTTPS_FORWARD_LOG}" 2>&1 < /dev/null &
  else
    env -u RUNNER_TRACKING_ID nohup "${HTTPS_FORWARD_CMD[@]}" > "${HTTPS_FORWARD_LOG}" 2>&1 < /dev/null &
  fi

  for attempt in 1 2 3 4 5; do
    sleep 2
    if curl -kfsS "https://127.0.0.1:${HTTPS_PORT}/" >/dev/null; then
      break
    fi
    if [ "${attempt}" = "5" ]; then
      echo "HTTPS ingress did not become ready on 127.0.0.1:${HTTPS_PORT}"
      cat "${HTTPS_FORWARD_LOG}" || true
      exit 1
    fi
  done
fi

echo "HTTPS ingress port-forward status:"
pgrep -af "[k]ubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller ${HTTPS_PORT}:443" || true
cat "${HTTPS_FORWARD_LOG}" || true

if command -v ufw >/dev/null 2>&1; then
  if sudo -n true >/dev/null 2>&1; then
    sudo ufw allow "${HTTPS_PORT}/tcp" || true
  else
    echo "Run manually on the Minikube server:"
    echo "sudo ufw allow ${HTTPS_PORT}/tcp"
  fi
fi

echo "HTTPS access check:"
curl -kI --max-time 5 "https://127.0.0.1:${HTTPS_PORT}/" || true
curl -kI --max-time 5 "https://${SERVER_IP}:${HTTPS_PORT}/" || true

cat <<EOF

Deployment applied.

Primary HTTPS access:

https://${SERVER_IP}/

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
