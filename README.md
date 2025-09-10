# Contractor Billing Application

A comprehensive contractor billing platform built with Next.js and FastAPI.

## Architecture

- **Frontend**: Next.js 14+ with App Router, TypeScript, Tailwind CSS, Shadcn/ui
- **Backend**: FastAPI with PostgreSQL, SQLAlchemy, Alembic
- **Deployment**: Vercel (frontend), Fly.io/Render (backend)

## Key Features

- Flexible billing rules engine
- Mobile-first time & expense tracking
- PWA with offline support
- Multi-tenant RBAC
- Subcontractor management
- Change order handling
- Real-time approvals
- Invoice generation with PDF export

## Project Structure

```
frontend/           # Next.js application
backend/           # FastAPI application  
infra/             # Deployment configurations
scripts/           # Development utility scripts
```

## Getting Started

### Prerequisites
- Python 3.13+ installed
- Node.js 18+ installed
- PyCharm IDE (recommended)

### Quick Start
1. **Backend setup**: Virtual environment already configured in `backend/venv/`
2. **Frontend setup**: `cd frontend && npm install` (if not done)
3. **Run full stack**: Use PyCharm compound run configuration "Full Stack"
4. **Or run manually**:
   ```bash
   # Terminal 1 - Backend
   cd backend && venv\Scripts\python.exe -m uvicorn app.main:app --reload
   
   # Terminal 2 - Frontend  
   cd frontend && npm run dev
   ```

### Access Points
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

## Development Phases

- Phase 0: Project setup (1-2 weeks)
- Phase 1: MVP - Core billing & approvals (4-6 weeks) 
- Phase 2: Advanced billing & change orders (3-4 weeks)
- Phase 3: Integrations & real-time (3-5 weeks)
- Phase 4: Modularity & pricing (2-3 weeks)
- Phase 5: Analytics & reporting