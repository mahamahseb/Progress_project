#!/usr/bin/env bash
set -euo pipefail

LAB1_IP="${LAB1_IP:-192.168.239.141}"
MINIKUBE_INGRESS_IP="${MINIKUBE_INGRESS_IP:-192.168.49.2}"
PROGRESS_HOST="${PROGRESS_HOST:-progress-tracker.mah.com}"
PROGRESS_SSLIP_HOST="${PROGRESS_SSLIP_HOST:-progress-tracker.192.168.239.141.sslip.io}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

echo "== lab1 ingress setup =="
echo "lab1 IP: ${LAB1_IP}"
echo "Minikube ingress IP: ${MINIKUBE_INGRESS_IP}"

require_cmd sudo
require_cmd systemctl
require_cmd kubectl

if ! command -v socat >/dev/null 2>&1; then
  echo "socat is not installed. Installing with apt..."
  sudo apt-get update
  sudo apt-get install -y socat
fi

echo "Writing systemd services..."
sudo tee /etc/systemd/system/lab1-ingress-80.service >/dev/null <<EOF
[Unit]
Description=Forward lab1 HTTP traffic to Minikube ingress
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:80,fork,reuseaddr TCP:${MINIKUBE_INGRESS_IP}:80
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/lab1-ingress-443.service >/dev/null <<EOF
[Unit]
Description=Forward lab1 HTTPS traffic to Minikube ingress
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:443,fork,reuseaddr TCP:${MINIKUBE_INGRESS_IP}:443
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling services..."
sudo systemctl daemon-reload
sudo systemctl enable --now lab1-ingress-80.service
sudo systemctl enable --now lab1-ingress-443.service

echo "Waiting briefly for services..."
sleep 3

echo
echo "== systemd status =="
systemctl --no-pager --lines=5 status lab1-ingress-80.service || true
systemctl --no-pager --lines=5 status lab1-ingress-443.service || true

echo
echo "== listening ports =="
ss -ltnp | grep -E ':80|:443' || true

echo
echo "== ingress resources =="
kubectl get ingress -A || true

echo
echo "== DNS checks =="
nslookup "${PROGRESS_HOST}" || true

echo
echo "== local HTTP/HTTPS checks =="
curl -I --max-time 10 -H "Host: ${PROGRESS_HOST}" "http://127.0.0.1/" || true
curl -kI --max-time 10 -H "Host: ${PROGRESS_HOST}" "https://127.0.0.1/" || true
curl -kI --max-time 10 "https://${PROGRESS_SSLIP_HOST}/" || true
curl -kI --max-time 10 "https://${PROGRESS_HOST}/" || true

echo
echo "Done."
echo "Open from browser:"
echo "https://${PROGRESS_SSLIP_HOST}/"
echo "https://${PROGRESS_HOST}/"
