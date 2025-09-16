from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models.projects import Project, BillingModelEnum
from app.db.models.clients import Client
from app.db.models.users import User
from app.core.deps import get_current_active_user, require_manager
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from uuid import UUID
import uuid

router = APIRouter()

class ProjectBase(BaseModel):
    name: str
    code: str
    status: str = "ACTIVE"
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    notes: Optional[str] = None
    billing_model: BillingModelEnum = BillingModelEnum.HOURLY
    billing_settings: Optional[Dict[str, Any]] = None

class ProjectCreate(ProjectBase):
    client_id: UUID

class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    status: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    notes: Optional[str] = None
    billing_model: Optional[BillingModelEnum] = None
    billing_settings: Optional[Dict[str, Any]] = None

class ProjectResponse(ProjectBase):
    id: UUID
    org_id: UUID
    client_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True

@router.get("/", response_model=List[ProjectResponse])
async def list_projects(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    client_id: Optional[UUID] = Query(None),
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    List projects for the current organization with optional filters.
    """
    query = db.query(Project).filter(Project.org_id == current_user.org_id)

    if client_id:
        query = query.filter(Project.client_id == client_id)

    if status:
        query = query.filter(Project.status == status)

    if search:
        query = query.filter(
            (Project.name.ilike(f"%{search}%")) |
            (Project.code.ilike(f"%{search}%"))
        )

    projects = query.offset(skip).limit(limit).all()
    return projects

@router.post("/", response_model=ProjectResponse)
async def create_project(
    project_data: ProjectCreate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Create a new project (requires MANAGER or ADMIN role).
    """
    # Verify client exists and belongs to the organization
    client = db.query(Client).filter(
        Client.id == project_data.client_id,
        Client.org_id == current_user.org_id
    ).first()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )

    # Check if project code already exists in org
    existing_project = db.query(Project).filter(
        Project.org_id == current_user.org_id,
        Project.code == project_data.code
    ).first()
    if existing_project:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Project code already exists"
        )

    db_project = Project(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        **project_data.dict()
    )
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(
    project_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific project by ID within the current organization.
    """
    project = db.query(Project).filter(
        Project.id == project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )
    return project

@router.patch("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: UUID,
    project_update: ProjectUpdate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Update a project's information (requires MANAGER or ADMIN role).
    """
    project = db.query(Project).filter(
        Project.id == project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    update_data = project_update.dict(exclude_unset=True)

    # Check code uniqueness if code is being updated
    if "code" in update_data:
        existing_project = db.query(Project).filter(
            Project.org_id == current_user.org_id,
            Project.code == update_data["code"],
            Project.id != project_id
        ).first()
        if existing_project:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Project code already exists"
            )

    for field, value in update_data.items():
        setattr(project, field, value)

    db.commit()
    db.refresh(project)
    return project

@router.delete("/{project_id}")
async def delete_project(
    project_id: UUID,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Delete a project (requires MANAGER or ADMIN role).
    Only allowed if no time entries or other related data exist.
    """
    project = db.query(Project).filter(
        Project.id == project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    # Check if project has any time entries
    from app.db.models.time_entries import TimeEntry
    time_entry_count = db.query(TimeEntry).filter(TimeEntry.project_id == project_id).count()
    if time_entry_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete project with {time_entry_count} time entries"
        )

    # Check if project has any expenses
    from app.db.models.expenses import Expense
    expense_count = db.query(Expense).filter(Expense.project_id == project_id).count()
    if expense_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete project with {expense_count} expenses"
        )

    db.delete(project)
    db.commit()
    return {"message": "Project deleted successfully"}