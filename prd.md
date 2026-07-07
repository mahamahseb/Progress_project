# PRD: Project Progress Tracker

## Goal

สร้างระบบ web dashboard สำหรับติดตามเปอร์เซ็นต์การพัฒนาโปรเจกต์แบบใกล้ real-time จากไฟล์ `prd.md` ของแต่ละ repository

## Users

- Project owner ที่ต้องการเห็นภาพรวมความคืบหน้าของหลายระบบ
- Developer ที่อัปเดต task ผ่าน `prd.md`
- Manager ที่ต้องการดูสถานะล่าสุดหลังทีม push code ขึ้น GitHub

## MVP Scope

- [x] ลงทะเบียน project พร้อม repository, branch และ path ของ `prd.md`
- [x] อ่านไฟล์ `prd.md` จาก local path สำหรับโหมด dev
- [x] อ่านไฟล์ `prd.md` จาก GitHub สำหรับโหมด production
- [x] Parse checkbox task จาก Markdown
- [x] แบ่ง task ตาม heading หรือ section
- [x] คำนวณเปอร์เซ็นต์จาก completed tasks / total tasks
- [x] เปิด API สำหรับดู project list
- [x] เปิด API สำหรับดู project detail พร้อม task breakdown
- [x] เปิด API สำหรับ sync หลัง GitHub push
- [x] เก็บ sync log เพื่อ debug ได้ง่าย
- [x] แสดง dashboard หน้าแรก
- [x] แสดงรายละเอียด project และ task list
- [x] เตรียม GitHub Actions example

## Documentation Standard Tasks

- [x] Rename repository source-of-truth PRD to `PRD.md`
- [x] Add root documentation files for architecture, API, database, deployment, security, testing, standards, decisions, TODO, and changelog
- [x] Add detailed documentation folders under `docs/`
- [x] Add placeholder folders for source, tests, scripts, migrations, configs, docker, Kubernetes, assets, and tools
- [x] Update `AGENTS.md` and `README.md` to reference the new documentation standard

## Deployment Tasks

- [x] Adapt Minikube deployment guide for Progress Tracker
- [x] Add frontend Dockerfile
- [x] Add Kubernetes manifest for backend, frontend, PVC, services, and ingress
- [x] Document image build, Minikube image load, rollout, port-forward, and health check commands
- [x] Split frontend server-side API base from browser-side API base
- [x] Use port `8081` for Progress Tracker ingress port-forward to avoid conflict with existing Minikube apps
- [x] Add Minikube deployment helper script

## CI Tasks

- [x] Add GitHub Actions CI workflow
- [x] Run backend tests in CI
- [x] Build frontend in CI
- [x] Validate Kubernetes manifest in CI
- [x] Build backend and frontend Docker images in CI without pushing
- [x] Publish backend and frontend images to DockerHub after main branch CI succeeds

## CD Tasks

- [x] Add manual GitHub Actions deployment workflow for Minikube
- [x] Require self-hosted Linux runner for deployment
- [x] Document self-hosted runner requirements
- [x] Keep long-running ingress port-forward outside the GitHub Actions job
- [x] Add self-hosted runner installer script
- [x] Deploy Minikube from DockerHub images using the pushed Git commit tag

## Out of Scope for MVP

- Role-based access control
- Multi-tenant billing
- Advanced analytics
- AI summary
- Auto-edit `prd.md`

## PRD Task Format

ระบบ MVP จะอ่าน task จากรูปแบบนี้:

```md
- [x] Completed task
- [ ] Pending task
```

รองรับ section จาก heading:

```md
## Backend
- [x] Create API
- [ ] Add tests
```

## Backend Tasks

- [x] Setup FastAPI project
- [x] Create settings module
- [x] Create SQLite repository for MVP
- [x] Create project schemas
- [x] Create task schemas
- [x] Create PRD parser
- [x] Create progress calculator
- [x] Create project service
- [x] Create sync service
- [x] Create project API routes
- [x] Create sync API route
- [x] Add parser tests
- [x] Add progress calculator tests

## Frontend Tasks

- [x] Setup Next.js project
- [x] Create dashboard page
- [x] Create project list component
- [x] Create progress bar component
- [x] Create project detail page
- [x] Connect dashboard to backend API

## GitHub Integration Tasks

- [x] Create GitHub client
- [x] Support GitHub token from env
- [x] Fetch `prd.md` by repo, branch, path
- [x] Create GitHub Actions example
- [x] Add sync token protection

## Success Criteria

- Dashboard แสดง progress ของ sample project ได้
- Parser อ่าน task จาก `examples/sample-project/prd.md` ได้ถูกต้อง
- API sync สามารถรับ payload แล้วคำนวณ progress ใหม่ได้
- โค้ดแต่ละส่วนแก้ตรงจุดโดยไม่ต้องไล่ทั้งระบบ
