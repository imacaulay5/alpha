@echo off
echo Starting Contractor Billing Development Environment...

start "Frontend" cmd /c "cd frontend && npm run dev"
start "Backend" cmd /c "cd backend && venv\Scripts\python.exe -m uvicorn app.main:app --reload"

echo Both frontend and backend are starting...
echo Frontend: http://localhost:3000
echo Backend: http://localhost:8000
echo API Docs: http://localhost:8000/docs