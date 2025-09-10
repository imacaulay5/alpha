# Development Setup Guide

## Python Virtual Environment Setup

### Automatic Setup (Recommended)

**Windows:**
```bash
cd backend
setup_env.bat
```

**Linux/macOS:**
```bash
cd backend
./setup_env.sh
```

### Manual Setup

1. Create virtual environment:
```bash
cd backend
python -m venv venv
```

2. Activate virtual environment:
```bash
# Windows
venv\Scripts\activate.bat

# Linux/macOS
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-dev.txt
pip install -e .
```

## PyCharm Setup

### 1. Configure Python Interpreter

1. Open PyCharm and load the project
2. Go to **File → Settings** (or **PyCharm → Preferences** on macOS)
3. Navigate to **Project → Python Interpreter**
4. Click the gear icon → **Add...**
5. Select **Existing Environment**
6. Browse to: `backend/venv/Scripts/python.exe` (Windows) or `backend/venv/bin/python` (Linux/macOS)
7. Click **OK**

### 2. Run Configurations

The project includes pre-configured run configurations:

- **FastAPI Server** - Standard development server
- **FastAPI Server (Debug)** - Debug mode with detailed logging
- **Run Tests** - Execute all tests

These configurations will appear in your run/debug dropdown automatically.

### 3. Debugging

To debug your FastAPI application:

1. Set breakpoints in your code by clicking the left margin
2. Select **FastAPI Server (Debug)** from the run configuration dropdown
3. Click the **Debug** button (bug icon) instead of **Run**
4. Your application will start in debug mode
5. When a breakpoint is hit, you can:
   - Inspect variables
   - Step through code
   - Evaluate expressions
   - View the call stack

### 4. Environment Variables

Create a `.env` file in the `backend` directory with your configuration:

```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/contractor_billing
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=your-development-secret-key
DEBUG=1
```

## Database Setup

### Using Docker (Recommended)

```bash
cd infra
docker-compose up -d postgres redis
```

### Local PostgreSQL

1. Install PostgreSQL locally
2. Create database: `contractor_billing`
3. Update `DATABASE_URL` in `.env`

### Run Migrations

```bash
cd backend
# Activate virtual environment first
alembic upgrade head
```

## Running the Application

### Development Server

```bash
cd backend
# Activate virtual environment
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Using PyCharm

1. Select **FastAPI Server** or **FastAPI Server (Debug)** configuration
2. Click **Run** or **Debug**

### API Documentation

Once running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Frontend Development

```bash
cd frontend
npm install
npm run dev
```

The frontend will be available at http://localhost:3000

## Testing

### Run Tests

```bash
cd backend
# Activate virtual environment
pytest
```

### Using PyCharm

Select **Run Tests** configuration and click **Run** or **Debug**

### Test Coverage

```bash
pytest --cov=app --cov-report=html
```

## Code Quality

### Format Code

```bash
black app/
isort app/
```

### Lint Code

```bash
flake8 app/
mypy app/
```

## Debugging Tips

### FastAPI Debug Mode

Set `DEBUG=1` in your environment to enable:
- Detailed error messages
- Auto-reload on code changes
- Enhanced logging

### Database Debugging

Enable SQL logging by adding to your `.env`:
```env
SQLALCHEMY_ECHO=1
```

### Breakpoint Debugging

In your code, you can add:
```python
import debugpy
debugpy.breakpoint()
```

Or use PyCharm's visual breakpoints for a better experience.

## Common Issues

### Port Already in Use

If port 8000 is busy:
```bash
# Find and kill the process
netstat -ano | findstr :8000  # Windows
lsof -ti:8000 | xargs kill    # Linux/macOS
```

### Virtual Environment Issues

If you encounter import errors:
1. Ensure virtual environment is activated
2. Verify Python interpreter in PyCharm settings
3. Reinstall dependencies: `pip install -r requirements.txt`

### Database Connection Issues

1. Ensure PostgreSQL is running
2. Check `DATABASE_URL` in `.env`
3. Test connection: `psql postgresql://postgres:password@localhost:5432/contractor_billing`