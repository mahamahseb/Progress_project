#!/usr/bin/env bash
set -euo pipefail

CLEAN_ROOT="${CLEAN_ROOT:-$HOME/Progress_project}"

echo "Cleaning Minikube server workspace..."

if [ -d "${CLEAN_ROOT}" ]; then
  case "${CLEAN_ROOT}" in
    "$HOME"/Progress_project|"$HOME"/Progress_project/)
      echo "Cleaning generated files under ${CLEAN_ROOT}"
      ;;
    *)
      echo "Refusing to clean unexpected path: ${CLEAN_ROOT}"
      exit 1
      ;;
  esac

  rm -rf \
    "${CLEAN_ROOT}/.docker-codex" \
    "${CLEAN_ROOT}/.docker-config" \
    "${CLEAN_ROOT}/.next" \
    "${CLEAN_ROOT}/.npm-cache" \
    "${CLEAN_ROOT}/.pnpm-store" \
    "${CLEAN_ROOT}/.pytest_cache" \
    "${CLEAN_ROOT}/.pytest-tmp" \
    "${CLEAN_ROOT}/.tmp" \
    "${CLEAN_ROOT}/.tools" \
    "${CLEAN_ROOT}/backend/.pytest_cache" \
    "${CLEAN_ROOT}/backend/.pytest-tmp" \
    "${CLEAN_ROOT}/backend/__pycache__" \
    "${CLEAN_ROOT}/frontend/.next" \
    "${CLEAN_ROOT}/frontend/node_modules" \
    "${CLEAN_ROOT}/node_modules" \
    "${CLEAN_ROOT}/.tools-gh-release.json" \
    "${CLEAN_ROOT}/progress_tracker.db"
else
  echo "${CLEAN_ROOT} does not exist; skipping workspace cleanup."
fi

echo "Removing old locally built Docker images from the host daemon..."
if command -v docker >/dev/null 2>&1; then
  docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' |
    awk '$1 ~ /^progress-tracker-(backend|frontend):/ { print $2 }' |
    sort -u |
    xargs -r docker rmi -f
else
  echo "docker is not installed; skipping host Docker image cleanup."
fi

echo "Removing old locally loaded images from Minikube..."
if command -v minikube >/dev/null 2>&1; then
  minikube image rm progress-tracker-backend:latest >/dev/null 2>&1 || true
  minikube image rm progress-tracker-frontend:latest >/dev/null 2>&1 || true
else
  echo "minikube is not installed; skipping Minikube image cleanup."
fi

echo "Keeping DockerHub images currently referenced by deployments:"
kubectl get deployment -n progress-tracker progress-tracker-backend \
  -o jsonpath='backend={.spec.template.spec.containers[0].image}{"\n"}' || true
kubectl get deployment -n progress-tracker progress-tracker-frontend \
  -o jsonpath='frontend={.spec.template.spec.containers[0].image}{"\n"}' || true

echo "Cleanup complete."
