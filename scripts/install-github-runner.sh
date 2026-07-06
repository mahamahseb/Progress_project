#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/mahamahseb/Progress_project}"
RUNNER_VERSION="${RUNNER_VERSION:-2.328.0}"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner-progress-tracker}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,progress-tracker,minikube}"
RUNNER_NAME="${RUNNER_NAME:-progress-tracker-minikube}"

if [[ -z "${RUNNER_TOKEN:-}" ]]; then
  echo "RUNNER_TOKEN is required."
  echo "Create it in GitHub: Settings -> Actions -> Runners -> New self-hosted runner"
  echo "Then run:"
  echo "RUNNER_TOKEN=<token> bash scripts/install-github-runner.sh"
  exit 1
fi

mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

if [[ ! -f config.sh ]]; then
  echo "Downloading GitHub Actions runner ${RUNNER_VERSION}..."
  curl -fsSL -o actions-runner-linux-x64.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  tar xzf actions-runner-linux-x64.tar.gz
fi

if [[ -f .runner ]]; then
  echo "Runner is already configured in ${RUNNER_DIR}."
else
  echo "Configuring runner..."
  ./config.sh \
    --url "${REPO_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace
fi

echo "Installing runner service..."
sudo ./svc.sh install
sudo ./svc.sh start

echo "Runner service status:"
sudo ./svc.sh status

cat <<EOF

Self-hosted runner installed.

Repo: ${REPO_URL}
Name: ${RUNNER_NAME}
Labels: ${RUNNER_LABELS}

Next:
1. Open GitHub -> Actions -> Deploy to Minikube -> Run workflow
2. Use port_forward_port: 8081
EOF
