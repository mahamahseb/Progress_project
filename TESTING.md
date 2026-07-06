# Testing Strategy

## Backend

Run:

```powershell
cd backend
python -m pytest
```

Windows temp permission workaround:

```powershell
cd backend
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$env:TEMP=(Resolve-Path ..).Path + "\.tmp-$stamp"
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Force -Path $env:TEMP | Out-Null
python -m pytest -p no:cacheprovider --basetemp "..\.pytest-tmp-$stamp"
```

## Frontend

Run:

```powershell
cd frontend
npm run build
```
