# Architecture

## Principle

ระบบนี้แยกโค้ดตามหน้าที่ เพื่อให้แก้ไขตรงจุด:

- `parsers/` อ่าน `prd.md`
- `progress/` คำนวณเปอร์เซ็นต์
- `sync/` ควบคุม flow หลัง push
- `projects/` จัดเก็บและคืนข้อมูล project
- `api/routes/` รับ request แล้วส่งต่อให้ service

## MVP Flow

```txt
GitHub Actions
  -> POST /api/sync/github
  -> sync service
  -> read prd.md
  -> parser
  -> progress calculator
  -> project repository
  -> dashboard API
```

## จุดที่แก้บ่อย

```txt
เปลี่ยนรูปแบบ prd.md        backend/app/parsers/prd_parser.py
เปลี่ยนสูตร progress         backend/app/modules/progress/calculator.py
เปลี่ยนข้อมูล project        backend/app/modules/projects/schema.py
เปลี่ยน sync payload          backend/app/modules/sync/schema.py
เปลี่ยนหน้า dashboard        frontend/src/features/projects
```
