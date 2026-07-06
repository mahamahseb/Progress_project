# Runbook

## Start Backend

```powershell
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Start Frontend

```powershell
cd frontend
$env:NEXT_PUBLIC_API_BASE_URL='http://127.0.0.1:8000'
npm run dev
```
