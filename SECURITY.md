# Security Standard

## Current Controls

- Sync endpoint uses bearer token authentication.
- GitHub token is read from environment variables.
- `.env` and database files are ignored by git.
- Private repositories require `GITHUB_TOKEN`.

## Follow-Up Areas

- User authentication.
- Role-based authorization.
- Audit log retention.
- Rate limiting.
- Webhook signature verification.
