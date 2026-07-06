# Docker

## Backend

Build from project root:

```bash
docker build -t progress-tracker-backend:latest -f backend/Dockerfile .
```

## Frontend

Build from project root:

```bash
docker build -t progress-tracker-frontend:latest -f frontend/Dockerfile ./frontend
```

## Docker Compose

Local compose entry exists in `docker-compose.yml`.
