# updateMinikube.md

## Purpose

Use this file to update any project that deploys to the shared lab Minikube environment.

The current Minikube architecture uses one shared ingress entrypoint on `lab1`. Each application project should only manage its own Kubernetes app resources, not the shared lab networking layer.

## Target Architecture

```txt
Browser
  |
  | https://<app>.mah.com
  | https://<app>.192.168.239.141.sslip.io
  v
DNS
  |
  | <app>.mah.com resolves to 192.168.239.141
  v
lab1:443
  |
  | lab1-ingress-443.service
  | socat forwarder
  v
Minikube ingress: 192.168.49.2:443
  |
  v
NGINX Ingress Controller
  |
  v
Application Ingress
  |
  v
Application Service
  |
  v
Application Pods
```

HTTP uses the same shared path:

```txt
Browser
  |
  | http://<app>.mah.com
  v
lab1:80
  |
  | lab1-ingress-80.service
  | socat forwarder
  v
Minikube ingress: 192.168.49.2:80
  |
  v
NGINX Ingress Controller
```

## Shared Infrastructure

The shared infrastructure is owned by the lab/server layer, not by each application project.

Do not recreate or modify these from normal app deploy scripts:

- BIND DNS server
- `lab1-ingress-80.service`
- `lab1-ingress-443.service`
- `socat` port forwarding
- NGINX Ingress Controller installation
- firewall rules for ports `80` and `443`

The shared services should already exist on `lab1`:

```txt
lab1-ingress-80.service
lab1-ingress-443.service
```

Expected forwarding:

```txt
lab1:80  -> 192.168.49.2:80
lab1:443 -> 192.168.49.2:443
```

## Application Ownership

Each project should manage only its own Kubernetes resources:

- Namespace
- Deployment
- Service
- Ingress
- Secret
- ConfigMap
- PVC, if needed

Each project deploy script should normally do only:

```bash
kubectl apply -f k8s/
kubectl rollout status deployment/<deployment-name> -n <namespace>
kubectl get ingress -n <namespace>
```

## Required App Hostnames

For every app, define two hostnames:

```txt
<app>.mah.com
<app>.192.168.239.141.sslip.io
```

Example for app `customer-system`:

```txt
customer-system.mah.com
customer-system.192.168.239.141.sslip.io
```

The `mah.com` hostname must be added to lab DNS.

The `sslip.io` hostname resolves automatically and does not need a DNS record.

## DNS Requirement

For each app, add a DNS record:

```txt
<app>.mah.com -> 192.168.239.141
```

Example:

```txt
customer-system.mah.com -> 192.168.239.141
```

Verify:

```bash
nslookup customer-system.mah.com
```

Expected:

```txt
192.168.239.141
```

## Ingress Template

Update the project Ingress to include both hostnames.

Replace:

- `<namespace>`
- `<ingress-name>`
- `<app>`
- `<service-name>`
- `<service-port>`
- `<tls-secret-name>`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <ingress-name>
  namespace: <namespace>
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - <app>.mah.com
        - <app>.192.168.239.141.sslip.io
      secretName: <tls-secret-name>
  rules:
    - host: <app>.mah.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service-name>
                port:
                  number: <service-port>
    - host: <app>.192.168.239.141.sslip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service-name>
                port:
                  number: <service-port>
```

## TLS

For lab use, a self-signed TLS secret is acceptable.

Example:

```bash
APP_HOST="<app>.mah.com"
APP_SSLIP_HOST="<app>.192.168.239.141.sslip.io"
NAMESPACE="<namespace>"
TLS_SECRET="<tls-secret-name>"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/app-tls.key \
  -out /tmp/app-tls.crt \
  -subj "/CN=${APP_HOST}" \
  -addext "subjectAltName = DNS:${APP_HOST},DNS:${APP_SSLIP_HOST}"

kubectl create secret tls "${TLS_SECRET}" \
  -n "${NAMESPACE}" \
  --cert=/tmp/app-tls.crt \
  --key=/tmp/app-tls.key \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Deploy Script Rule

Remove or disable app-specific long-running port-forward logic.

Avoid this in app deploy scripts:

```bash
kubectl port-forward --address 0.0.0.0 ...
```

Avoid app deploy scripts that create or replace:

```txt
lab1-ingress-80.service
lab1-ingress-443.service
```

If a project still needs temporary fallback access, make it opt-in only:

```bash
MANAGE_DIRECT_PORT_FORWARD=1 bash scripts/deploy.sh
```

Default behavior should be:

```txt
MANAGE_DIRECT_PORT_FORWARD=0
MANAGE_HTTPS_FORWARDER=0
```

## Migration Checklist

Use this checklist for each existing project:

- [ ] Identify the Kubernetes namespace.
- [ ] Identify the frontend or public service name.
- [ ] Identify the public service port.
- [ ] Add `<app>.mah.com` DNS record pointing to `192.168.239.141`.
- [ ] Add `<app>.mah.com` to the Ingress rules.
- [ ] Add `<app>.192.168.239.141.sslip.io` to the Ingress rules.
- [ ] Add both hostnames to the Ingress TLS hosts.
- [ ] Create or update the TLS secret with both hostnames in SAN.
- [ ] Remove app-owned port `80` or `443` forwarding logic.
- [ ] Keep lab1 `socat` and DNS setup outside the app deploy.
- [ ] Apply Kubernetes manifests.
- [ ] Verify Ingress.
- [ ] Test HTTPS from server.
- [ ] Test HTTPS from browser.

## Commands To Apply App Manifests

Run from the project root on the Minikube server:

```bash
kubectl apply -f k8s/
kubectl get ingress -A
kubectl get pods -n <namespace>
kubectl get svc -n <namespace>
```

If the project has one combined manifest:

```bash
kubectl apply -f k8s/<app>.yaml
```

## Verification Commands

On lab1:

```bash
systemctl status lab1-ingress-80.service lab1-ingress-443.service --no-pager
ss -ltnp | grep -E ':80|:443'
kubectl get ingress -A
```

Check DNS:

```bash
nslookup <app>.mah.com
```

Check routing through HTTP:

```bash
curl -I -H "Host: <app>.mah.com" http://127.0.0.1/
```

Check routing through HTTPS:

```bash
curl -kI -H "Host: <app>.mah.com" https://127.0.0.1/
curl -kI https://<app>.mah.com/
curl -kI https://<app>.192.168.239.141.sslip.io/
```

Expected result:

```txt
HTTP 200, 301, 302, or 308 is acceptable.
HTTPS should eventually return 200 for a working app.
```

## Troubleshooting

If `sslip.io` works but `<app>.mah.com` does not:

```txt
Likely problem: DNS or missing Ingress host rule.
```

Check:

```bash
nslookup <app>.mah.com
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>
```

If both hostnames return NGINX `404 Not Found`:

```txt
Likely problem: Ingress host or service backend mismatch.
```

Check:

```bash
kubectl get svc -n <namespace>
kubectl get endpoints -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
```

If browser cannot connect at all:

```txt
Likely problem: lab1 port 80/443 forwarding or firewall.
```

Check:

```bash
systemctl status lab1-ingress-80.service lab1-ingress-443.service --no-pager
ss -ltnp | grep -E ':80|:443'
sudo ufw status
```

## AI Agent Instruction

When an AI coding agent updates a project for this Minikube architecture, it must:

- Keep lab1 infrastructure separate from app deployment.
- Update only project-owned Kubernetes manifests and docs.
- Add both `.mah.com` and `.sslip.io` hostnames to Ingress.
- Remove default long-running app-specific port-forward behavior.
- Provide exact verification commands for the project owner.
- Avoid changing unrelated source code.
