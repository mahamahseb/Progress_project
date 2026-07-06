# Project Progress Tracker

ระบบ web dashboard สำหรับติดตามเปอร์เซ็นต์การพัฒนาแต่ละโปรเจกต์จากไฟล์ `prd.md` โดยออกแบบให้ parser, progress calculation, GitHub sync และ dashboard แยกกันชัดเจนเพื่อแก้ไขง่าย

## MVP

- อ่าน task checkbox จาก `prd.md`
- คำนวณ progress จากจำนวน task ที่เสร็จแล้ว
- เปิด API สำหรับดู project และสั่ง sync
- เตรียม GitHub Actions example สำหรับเรียก sync หลัง push
- เตรียม frontend dashboard scaffold

## Structure

```txt
backend/    FastAPI API, parser, service, tests
frontend/   Next.js dashboard scaffold
docs/       เอกสารแยกตามหมวด business, architecture, data, ai, devops, security, network, operations
examples/   ตัวอย่าง prd.md และ GitHub Actions
PRD.md      PRD หลักของระบบนี้
AGENTS.md   กฎสำหรับ AI Coding Agent
```

## Backend quick start

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

บน Windows PowerShell:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

## Test

```bash
cd backend
pytest
```

ถ้า Windows ใช้ temp folder นอก workspace แล้วติด permission ให้ใช้:

```powershell
cd backend
$env:TEMP=(Resolve-Path ..).Path + '\.tmp'
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Force -Path $env:TEMP | Out-Null
python -m pytest -p no:cacheprovider --basetemp ..\.pytest-tmp
```

## GitHub sync

Backend จะอ่าน `prd.md` จาก GitHub เมื่อเรียก:

```http
POST /api/sync/github
Authorization: Bearer <SYNC_TOKEN>
```

payload:

```json
{
  "repo": "owner/repository",
  "branch": "main",
  "prd_path": "prd.md",
  "commit_sha": "optional"
}
```

สำหรับ private repo ให้ตั้งค่า `GITHUB_TOKEN` ใน backend environment

## Database

ค่าเริ่มต้นใช้ SQLite ที่ `backend/progress_tracker.db`

```txt
DATABASE_PATH=progress_tracker.db
```

ถ้าต้องการเก็บไว้ในโฟลเดอร์อื่น สามารถเปลี่ยน path ใน `.env` ได้

## Documentation

เอกสารมาตรฐานหลักอยู่ที่ root:

- `PRD.md`
- `AGENTS.md`
- `ARCHITECTURE.md`
- `SYSTEM_MAP.md`
- `DOMAIN_MODEL.md`
- `API.md`
- `DATABASE.md`
- `DEPLOYMENT.md`
- `SECURITY.md`
- `TESTING.md`
- `CODING_STANDARD.md`
- `CONTRIBUTING.md`
- `DECISIONS.md`
- `TODO.md`
- `CHANGELOG.md`

เอกสารรายละเอียดแยกตามหมวดอยู่ใน `docs/`
