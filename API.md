# API Specification

## Health

```http
GET /health
```

## Projects

```http
GET /api/projects
POST /api/projects
GET /api/projects/{project_id}
```

## Sync

```http
POST /api/sync/github
GET /api/sync/logs
```

`POST /api/sync/github` requires:

```http
Authorization: Bearer <SYNC_TOKEN>
```
