#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="progress-tracker-ingress-https"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-$HOME/.kube/config}"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as the normal Minikube user, not root."
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required."
  exit 1
fi

if ! kubectl get svc ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
  echo "ingress-nginx-controller service was not found. Run deploy first."
  exit 1
fi

echo "Creating systemd service ${SERVICE_NAME}..."
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<EOF
[Unit]
Description=Progress Tracker HTTPS ingress port-forward
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Environment=KUBECONFIG=${KUBECONFIG_PATH}
ExecStart=/snap/bin/kubectl -n ingress-nginx port-forward --address 0.0.0.0 svc/ingress-nginx-controller 443:443
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Opening firewall port 443 when ufw is available..."
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 443/tcp || true
fi

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

echo "Service status:"
sudo systemctl --no-pager status "${SERVICE_NAME}" || true

echo "Listening port:"
ss -ltnp | grep ':443 ' || true

echo "HTTPS check:"
curl -kI --max-time 10 https://progress-tracker.192.168.239.141.sslip.io/ || true
