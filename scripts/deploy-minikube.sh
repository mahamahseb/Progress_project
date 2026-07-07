#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="progress-tracker"
DOCKERHUB_NAMESPACE="${DOCKERHUB_NAMESPACE:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
USE_REMOTE_IMAGES="${USE_REMOTE_IMAGES:-}"
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
PORT_FORWARD_LOG="/tmp/progress-tracker-port-forward.log"
SERVER_IP="${SERVER_IP:-192.168.239.141}"
INGRESS_HOST="${INGRESS_HOST:-progress-tracker.192.168.239.141.sslip.io}"
HELLO_WORLD_NAMESPACE="${HELLO_WORLD_NAMESPACE:-hello-world}"
HELLO_WORLD_INGRESS="${HELLO_WORLD_INGRESS:-hello-world}"
HELLO_WORLD_HOST="${HELLO_WORLD_HOST:-hello.192.168.239.141.sslip.io}"
HTTPS_PORT="${HTTPS_PORT:-443}"
HTTPS_FORWARD_LOG="/tmp/progress-tracker-https-port-forward.log"

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
  docker build -t "${FRONTEND_IMAGE}" -f frontend/Dockerfile ./frontend

  echo "Loading images into Minikube..."
  minikube image load "${BACKEND_IMAGE}"
  minikube image load "${FRONTEND_IMAGE}"
fi

echo "Enabling ingress..."
minikube addons enable ingress
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

echo "Ensuring hello-world ingress uses a dedicated host..."
if kubectl get ingress "${HELLO_WORLD_INGRESS}" -n "${HELLO_WORLD_NAMESPACE}" >/dev/null 2>&1; then
  echo "Preparing TLS certificate for https://${HELLO_WORLD_HOST}..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /tmp/hello-world-tls.key \
    -out /tmp/hello-world-tls.crt \
    -subj "/CN=${HELLO_WORLD_HOST}" \
    -addext "subjectAltName = DNS:${HELLO_WORLD_HOST}"
  kubectl create secret tls hello-world-tls \
    -n "${HELLO_WORLD_NAMESPACE}" \
    --cert=/tmp/hello-world-tls.crt \
    --key=/tmp/hello-world-tls.key \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl patch ingress "${HELLO_WORLD_INGRESS}" \
    -n "${HELLO_WORLD_NAMESPACE}" \
    --type=json \
    -p="[
      {\"op\":\"add\",\"path\":\"/spec/rules/0/host\",\"value\":\"${HELLO_WORLD_HOST}\"},
      {\"op\":\"add\",\"path\":\"/spec/tls\",\"value\":[{\"hosts\":[\"${HELLO_WORLD_HOST}\"],\"secretName\":\"hello-world-tls\"}]}
    ]" || \
  kubectl patch ingress "${HELLO_WORLD_INGRESS}" \
    -n "${HELLO_WORLD_NAMESPACE}" \
    --type=json \
    -p="[
      {\"op\":\"replace\",\"path\":\"/spec/rules/0/host\",\"value\":\"${HELLO_WORLD_HOST}\"},
      {\"op\":\"replace\",\"path\":\"/spec/tls\",\"value\":[{\"hosts\":[\"${HELLO_WORLD_HOST}\"],\"secretName\":\"hello-world-tls\"}]}
    ]"
  kubectl get ingress "${HELLO_WORLD_INGRESS}" -n "${HELLO_WORLD_NAMESPACE}" -o wide
else
  echo "No ${HELLO_WORLD_NAMESPACE}/${HELLO_WORLD_INGRESS} ingress found; skipping hello-world ingress update."
fi

echo "Preparing TLS certificate for https://${INGRESS_HOST}..."
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/progress-tracker-tls.key \
  -out /tmp/progress-tracker-tls.crt \
  -subj "/CN=${INGRESS_HOST}" \
  -addext "subjectAltName = DNS:${INGRESS_HOST}"
kubectl create secret tls progress-tracker-tls \
  -n "${NAMESPACE}" \
  --cert=/tmp/progress-tracker-tls.crt \
  --key=/tmp/progress-tracker-tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/progress-tracker.yaml

if [ "${USE_REMOTE_IMAGES}" = "1" ]; then
  echo "Pointing deployments at DockerHub images..."
  kubectl set image deployment/progress-tracker-backend backend="${BACKEND_IMAGE}" -n "${NAMESPACE}"
  kubectl set image deployment/progress-tracker-frontend frontend="${FRONTEND_IMAGE}" -n "${NAMESPACE}"
  kubectl patch deployment progress-tracker-backend -n "${NAMESPACE}" --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Always"}]'
  kubectl patch deployment progress-tracker-frontend -n "${NAMESPACE}" --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Always"}]'
else
  echo "Restarting deployments to use the latest loaded images..."
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

EFFECTIVE_HTTPS_PORT="${HTTPS_PORT}"
if [ "${HTTPS_PORT}" = "443" ] && ! sudo -n true >/dev/null 2>&1; then
  EFFECTIVE_HTTPS_PORT="8443"
  echo "sudo requires a password, so HTTPS will use fallback port ${EFFECTIVE_HTTPS_PORT}."
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

if command -v ufw >/dev/null 2>&1; then
  if sudo -n true >/dev/null 2>&1; then
    sudo ufw allow "${EFFECTIVE_HTTPS_PORT}/tcp" || true
  else
    echo "Run manually on the Minikube server:"
    echo "sudo ufw allow ${EFFECTIVE_HTTPS_PORT}/tcp"
  fi
fi

echo "HTTPS access check:"
curl -kI --max-time 5 -H "Host: ${INGRESS_HOST}" "https://127.0.0.1:${EFFECTIVE_HTTPS_PORT}/" || true
curl -kI --max-time 5 "https://${INGRESS_HOST}:${EFFECTIVE_HTTPS_PORT}/" || true

cat <<EOF

Deployment applied.

Images:

${BACKEND_IMAGE}
${FRONTEND_IMAGE}

Primary HTTPS ingress access:

https://${INGRESS_HOST}:${EFFECTIVE_HTTPS_PORT}/

This sslip.io hostname resolves to ${SERVER_IP}; no hosts-file edit is required.

hello-world ingress host:

https://${HELLO_WORLD_HOST}:${EFFECTIVE_HTTPS_PORT}/

Direct IP access:

http://<server-ip>:${PORT_FORWARD_PORT}/

Current server URL:

http://192.168.239.141:${PORT_FORWARD_PORT}/

NodePort fallback:

http://<server-ip>:30081/

Ingress host:

${INGRESS_HOST}

Direct health check:

curl http://127.0.0.1:${PORT_FORWARD_PORT}/health
EOF
