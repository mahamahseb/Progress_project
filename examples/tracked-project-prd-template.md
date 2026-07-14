# Progress Tracking

> Copy this section into the existing `prd.md` of the project you want to track.
> The Progress Tracker reads checkbox tasks from this file and calculates progress from completed tasks.

## Tracking Rules

- Use `- [ ]` for incomplete tasks.
- Use `- [x]` for completed tasks.
- Keep each task as one clear action.
- Do not put real tracking tasks inside fenced code blocks.
- Update checkbox status before or during each meaningful code push.

## Project Setup

- [ ] Confirm project name, repository, branch, and `prd.md` path
- [ ] Confirm local development command
- [ ] Confirm build command
- [ ] Confirm test command
- [ ] Confirm deployment target

## Development Progress

- [ ] Define or update application requirements
- [ ] Design or update application architecture
- [ ] Implement backend changes
- [ ] Implement frontend changes
- [ ] Connect frontend and backend
- [ ] Add or update database changes
- [ ] Add or update configuration files
- [ ] Add or update error handling
- [ ] Add or update logging

## Testing Progress

- [ ] Add or update unit tests
- [ ] Add or update integration tests
- [ ] Run backend tests
- [ ] Run frontend build
- [ ] Verify local application manually

## DevOps Progress

- [ ] Add or update Dockerfile
- [ ] Add or update docker-compose configuration
- [ ] Add or update Kubernetes manifests
- [ ] Add or update GitHub Actions CI
- [ ] Add or update GitHub Actions CD
- [ ] Build container image
- [ ] Push container image to registry
- [ ] Deploy to target environment
- [ ] Verify application URL

## Security Progress

- [ ] Confirm secrets are not committed
- [ ] Update `.env.example`
- [ ] Run dependency scan if available
- [ ] Run container scan if available
- [ ] Review exposed ports, ingress hosts, and access control

## Release Progress

- [ ] Update changelog or release notes
- [ ] Confirm final test result
- [ ] Confirm deployment result
- [ ] Confirm Progress Tracker dashboard shows the correct percentage
