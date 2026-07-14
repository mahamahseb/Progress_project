#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-progress-tracker}"
DOCKERHUB_NAMESPACE="${DOCKERHUB_NAMESPACE:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
USE_REMOTE_IMAGES="${USE_REMOTE_IMAGES:-}"
APP_VERSION="${APP_VERSION:-${GITHUB_SHA:-local}}"
if [ -n "${DOCKERHUB_NAMESPACE}" ]; then
  BACKEND_IMAGE="${BACKEND_IMAGE:-${DOCKERHUB_NAMESPACE}/progress-tracker-backend:${IMAGE_TAG}}"
  FRONTEND_IMAGE="${FRONTEND_IMAGE:-${DOCKERHUB_NAMESPACE}/progress-tracker-frontend:${IMAGE_TAG}}"
else
  BACKEND_IMAGE="${BACKEND_IMAGE:-progress-tracker-backend:latest}"
  FRONTEND_IMAGE="${FRONTEND_IMAGE:-progress-tracker-frontend:latest}"
fi
if [ -z "${USE_REMOTE_IMAGES}" ]; then
  if [ -n "${DOCKERHUB_NAMESPACE}" ]; then
    USE_REMOTE_IMAGES="1"
  else
    USE_REMOTE_IMAGES="0"
  fi
fi
PORT_FORWARD_PORT="${PORT_FORWARD_PORT:-8081}"
NODE_PORT="${NODE_PORT:-30081}"
PORT_FORWARD_LOG="/tmp/progress-tracker-port-forward.log"
SERVER_IP="${SERVER_IP:-192.168.239.141}"
INGRESS_HOST="${INGRESS_HOST:-progress-tracker.192.168.239.141.sslip.io}"
INGRESS_ALT_HOST="${INGRESS_ALT_HOST:-progress-tracker.mah.com}"
HTTPS_PORT="${HTTPS_PORT:-443}"
HTTPS_FORWARD_LOG="/tmp/progress-tracker-https-port-forward.log"
MANAGE_DIRECT_PORT_FORWARD="${MANAGE_DIRECT_PORT_FORWARD:-0}"
MANAGE_HTTPS_FORWARDER="${MANAGE_HTTPS_FORWARDER:-0}"

echo "Checking Minikube..."
minikube status
kubectl get nodes -o wide

if [ "${USE_REMOTE_IMAGES}" = "1" ]; then
  if [ -z "${DOCKERHUB_NAMESPACE}" ]; then
    echo "USE_REMOTE_IMAGES=1 requires DOCKERHUB_NAMESPACE."
    exit 1
  fi
  echo "Using DockerHub images:"
  echo "${BACKEND_IMAGE}"
  echo "${FRONTEND_IMAGE}"
  docker pull "${BACKEND_IMAGE}"
  docker pull "${FRONTEND_IMAGE}"
else
  echo "Building Docker images locally..."
  docker build -t "${BACKEND_IMAGE}" -f backend/Dockerfile .
  docker build --build-arg "APP_VERSION=${APP_VERSION}" -t "${FRONTEND_IMAGE}" -f frontend/Dockerfile ./frontend

  echo "Loading images into Minikube..."
  minikube image load "${BACKEND_IMAGE}"
  minikube image load "${FRONTEND_IMAGE}"
fi

echo "Checking shared ingress controller..."
kubectl get namespace ingress-nginx >/dev/null
kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

echo "Preparing TLS certificate for https://${INGRESS_HOST} and https://${INGRESS_ALT_HOST}..."
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/progress-tracker-tls.key \
  -out /tmp/progress-tracker-tls.crt \
  -subj "/CN=${INGRESS_HOST}" \
  -addext "subjectAltName = DNS:${INGRESS_HOST},DNS:${INGRESS_ALT_HOST}"
kubectl create secret tls progress-tracker-tls \
  -n "${NAMESPACE}" \
  --cert=/tmp/progress-tracker-tls.crt \
  --key=/tmp/progress-tracker-tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Kubernetes manifests..."
MANIFEST_PATH="$(mktemp)"
export NAMESPACE INGRESS_HOST INGRESS_ALT_HOST MANIFEST_PATH NODE_PORT
python3 - <<'PY'
import os
from pathlib import Path

namespace = os.environ["NAMESPACE"]
ingress_host = os.environ["INGRESS_HOST"]
ingress_alt_host = os.environ["INGRESS_ALT_HOST"]
node_port = os.environ["NODE_PORT"]
manifest_path = Path(os.environ["MANIFEST_PATH"])
source_path = Path("k8s/progress-tracker.yaml")

text = source_path.read_text()
text = text.replace("  name: progress-tracker\n---", f"  name: {namespace}\n---", 1)
text = text.replace("  namespace: progress-tracker", f"  namespace: {namespace}")
text = text.replace(
    ".progress-tracker.svc.cluster.local",
    f".{namespace}.svc.cluster.local",
)
text = text.replace("progress-tracker.192.168.239.141.sslip.io", ingress_host)
text = text.replace("progress-tracker.mah.com", ingress_alt_host)
text = text.replace("nodePort: 30081", f"nodePort: {node_port}")
manifest_path.write_text(text)
PY
kubectl apply -f "${MANIFEST_PATH}"
kubectl rollout status deployment/progress-tracker-postgres -n "${NAMESPACE}"

if [ "${USE_REMOTE_IMAGES}" = "1" ]; then
  echo "Pointing deployments at DockerHub images..."
  kubectl set image deployment/progress-tracker-backend backend="${BACKEND_IMAGE}" -n "${NAMESPACE}"
  kubectl set image deployment/progress-tracker-frontend frontend="${FRONTEND_IMAGE}" -n "${NAMESPACE}"
  kubectl set env deployment/progress-tracker-frontend "APP_VERSION=${APP_VERSION}" "NEXT_PUBLIC_APP_VERSION=${APP_VERSION}" -n "${NAMESPACE}"
  kubectl patch deployment progress-tracker-backend -n "${NAMESPACE}" --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Always"}]'
  kubectl patch deployment progress-tracker-frontend -n "${NAMESPACE}" --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Always"}]'
else
  echo "Restarting deployments to use the latest loaded images..."
  kubectl set env deployment/progress-tracker-frontend "APP_VERSION=${APP_VERSION}" "NEXT_PUBLIC_APP_VERSION=${APP_VERSION}" -n "${NAMESPACE}"
  kubectl rollout restart deployment/progress-tracker-backend -n "${NAMESPACE}"
  kubectl rollout restart deployment/progress-tracker-frontend -n "${NAMESPACE}"
fi

echo "Waiting for rollout..."
kubectl rollout status deployment/progress-tracker-backend -n "${NAMESPACE}"
kubectl rollout status deployment/progress-tracker-frontend -n "${NAMESPACE}"

echo "Current resources:"
kubectl get pods -n "${NAMESPACE}" -o wide
kubectl get svc -n "${NAMESPACE}"
kubectl get ingress -n "${NAMESPACE}" -o wide
kubectl get pvc -n "${NAMESPACE}"

if [ "${MANAGE_DIRECT_PORT_FORWARD}" = "1" ]; then
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
else
  echo "Skipping direct IP port-forward because MANAGE_DIRECT_PORT_FORWARD=${MANAGE_DIRECT_PORT_FORWARD}."
fi

EFFECTIVE_HTTPS_PORT="${HTTPS_PORT}"
HTTPS_URL_SUFFIX=""
if [ "${EFFECTIVE_HTTPS_PORT}" != "443" ]; then
  HTTPS_URL_SUFFIX=":${EFFECTIVE_HTTPS_PORT}"
fi

echo "Checking existing HTTPS ingress access on port ${EFFECTIVE_HTTPS_PORT}..."
if curl -kfsS -H "Host: ${INGRESS_HOST}" "https://127.0.0.1:${EFFECTIVE_HTTPS_PORT}/" >/dev/null; then
  echo "Existing HTTPS ingress access is ready on port ${EFFECTIVE_HTTPS_PORT}; reusing it."
else
  if [ "${MANAGE_HTTPS_FORWARDER}" != "1" ]; then
    echo "HTTPS ingress is not ready on 127.0.0.1:${EFFECTIVE_HTTPS_PORT}."
    echo "Not starting a forwarder because MANAGE_HTTPS_FORWARDER=${MANAGE_HTTPS_FORWARDER}."
    echo "Check lab1 infrastructure services:"
    echo "systemctl status lab1-ingress-80.service lab1-ingress-443.service"
    echo "ss -ltnp | grep -E ':80|:443'"
  else
    if [ "${HTTPS_PORT}" = "443" ] && ! sudo -n true >/dev/null 2>&1; then
      EFFECTIVE_HTTPS_PORT="8443"
      HTTPS_URL_SUFFIX=":${EFFECTIVE_HTTPS_PORT}"
      echo "sudo requires a password and port 443 is not ready, so HTTPS will use fallback port ${EFFECTIVE_HTTPS_PORT}."
    fi

    echo "Starting HTTPS ingress access on port ${EFFECTIVE_HTTPS_PORT}..."
    existing_https_pids="$(pgrep -f "[k]ubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller ${EFFECTIVE_HTTPS_PORT}:443" || true)"
    if [ -n "${existing_https_pids}" ]; then
      kill ${existing_https_pids} || true
      sleep 2
    fi

    if [ "${EFFECTIVE_HTTPS_PORT}" = "443" ]; then
      HTTPS_FORWARD_CMD=(sudo -E env "KUBECONFIG=${KUBECONFIG:-$HOME/.kube/config}" kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller "${EFFECTIVE_HTTPS_PORT}:443")
    else
      HTTPS_FORWARD_CMD=(kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller "${EFFECTIVE_HTTPS_PORT}:443")
    fi

    if command -v setsid >/dev/null 2>&1; then
      env -u RUNNER_TRACKING_ID setsid nohup "${HTTPS_FORWARD_CMD[@]}" > "${HTTPS_FORWARD_LOG}" 2>&1 < /dev/null &
    else
      env -u RUNNER_TRACKING_ID nohup "${HTTPS_FORWARD_CMD[@]}" > "${HTTPS_FORWARD_LOG}" 2>&1 < /dev/null &
    fi

    for attempt in 1 2 3 4 5; do
      sleep 2
      if curl -kfsS -H "Host: ${INGRESS_HOST}" "https://127.0.0.1:${EFFECTIVE_HTTPS_PORT}/" >/dev/null; then
        break
      fi
      if [ "${attempt}" = "5" ]; then
        echo "HTTPS ingress did not become ready on 127.0.0.1:${EFFECTIVE_HTTPS_PORT}"
        cat "${HTTPS_FORWARD_LOG}" || true
        exit 1
      fi
    done

    echo "HTTPS ingress port-forward status:"
    pgrep -af "[k]ubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller ${EFFECTIVE_HTTPS_PORT}:443" || true
    cat "${HTTPS_FORWARD_LOG}" || true
  fi
fi

echo "HTTPS access check:"
curl -kI --max-time 5 -H "Host: ${INGRESS_HOST}" "https://127.0.0.1:${EFFECTIVE_HTTPS_PORT}/" || true
curl -kI --max-time 5 -H "Host: ${INGRESS_ALT_HOST}" "https://127.0.0.1:${EFFECTIVE_HTTPS_PORT}/" || true
curl -kI --max-time 5 "https://${INGRESS_HOST}:${EFFECTIVE_HTTPS_PORT}/" || true
curl -kI --max-time 5 "https://${INGRESS_ALT_HOST}:${EFFECTIVE_HTTPS_PORT}/" || true

cat <<EOF

Deployment applied.

Images:

${BACKEND_IMAGE}
${FRONTEND_IMAGE}

Primary HTTPS ingress access:

https://${INGRESS_HOST}${HTTPS_URL_SUFFIX}/
https://${INGRESS_ALT_HOST}${HTTPS_URL_SUFFIX}/

This sslip.io hostname resolves to ${SERVER_IP}; no hosts-file edit is required.

Optional direct IP fallback:

http://<server-ip>:${PORT_FORWARD_PORT}/

Current server URL:

http://192.168.239.141:${PORT_FORWARD_PORT}/

NodePort fallback:

http://<server-ip>:30081/

Ingress host:

${INGRESS_HOST}
${INGRESS_ALT_HOST}

Optional direct health check:

curl http://127.0.0.1:${PORT_FORWARD_PORT}/health
EOF
