# lab1 Ingress Infrastructure

This folder describes the stable lab ingress layer that sits in front of Minikube.

Application repositories should not recreate this layer during every deploy. They should only create Kubernetes resources such as namespaces, deployments, services, PVCs, secrets, and ingress rules.

## Target Architecture

```txt
Browser
  |
  | http://*.mah.com
  | https://*.mah.com
  | http://*.192.168.239.141.sslip.io
  | https://*.192.168.239.141.sslip.io
  v
lab1:80 / lab1:443
  |
  | systemd socat forwarders
  v
Minikube ingress IP: 192.168.49.2:80 / 192.168.49.2:443
  |
  v
NGINX Ingress Controller
  |
  v
Application Ingress resources
```

## DNS

The following hostnames must resolve to the lab1 server IP:

```txt
progress-tracker.mah.com -> 192.168.239.141
hello.mah.com            -> 192.168.239.141
```

The `sslip.io` hostnames resolve automatically:

```txt
progress-tracker.192.168.239.141.sslip.io -> 192.168.239.141
hello.192.168.239.141.sslip.io            -> 192.168.239.141
```

## Systemd Services

Copy the service files into `/etc/systemd/system/` on lab1:

```bash
sudo cp infra/lab1/lab1-ingress-80.service /etc/systemd/system/
sudo cp infra/lab1/lab1-ingress-443.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now lab1-ingress-80.service
sudo systemctl enable --now lab1-ingress-443.service
```

## Verification

Run on lab1:

```bash
systemctl status lab1-ingress-80.service
systemctl status lab1-ingress-443.service
ss -ltnp | grep -E ':80|:443'
curl -I -H "Host: progress-tracker.mah.com" http://127.0.0.1/
curl -kI -H "Host: progress-tracker.mah.com" https://127.0.0.1/
```

Run from a client machine:

```bash
nslookup progress-tracker.mah.com
curl -kI https://progress-tracker.mah.com/
curl -kI https://progress-tracker.192.168.239.141.sslip.io/
```

## Ownership Boundary

Infrastructure layer:

```txt
DNS
socat services
Minikube ingress controller
lab1 firewall ports 80 and 443
```

Application layer:

```txt
Kubernetes Namespace
Deployment
Service
Ingress host rules
Secret
PVC
```
