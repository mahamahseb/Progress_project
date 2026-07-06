# GitHub Actions Setup

เพิ่ม workflow จาก `examples/github-action.yml` เข้า repository ที่ต้องการติดตาม

## Required secrets

```txt
PROGRESS_TRACKER_URL=https://your-progress-tracker.example.com
PROGRESS_TRACKER_TOKEN=your-secret-token
```

ค่า `PROGRESS_TRACKER_TOKEN` ต้องตรงกับ `SYNC_TOKEN` ใน backend

## Backend environment

```txt
SYNC_TOKEN=your-secret-token
GITHUB_TOKEN=optional-token-for-private-repos
```

ถ้า repository เป็น public สามารถปล่อย `GITHUB_TOKEN` ว่างได้ แต่ถ้าเป็น private ต้องใส่ token ที่อ่านไฟล์ใน repo ได้
