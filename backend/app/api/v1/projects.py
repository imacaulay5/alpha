from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models import Project, Client
from app.db.models.projects import BillingModelEnum
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
    db: Session = Depends(get_db)
):
    """
    List projects for the current organization with optional filters.
    """
    # TODO: Get current org from auth context
    # For now, use first org from database
    from app.db.models import Organization
    org = db.query(Organization).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    query = db.query(Project).filter(Project.org_id == org.id)
    
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
async def create_project(project: ProjectCreate, db: Session = Depends(get_db)):
    """
    Create a new project for the current organization.
    """
    # TODO: Get current org from auth context
    # For now, use first org from database
    from app.db.models import Organization
    org = db.query(Organization).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    # Verify client exists and belongs to the org
    client = db.query(Client).filter(
        Client.id == project.client_id,
        Client.org_id == org.id
    ).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")
    
    # Check if project code already exists in org
    existing_project = db.query(Project).filter(
        Project.org_id == org.id,
        Project.code == project.code
    ).first()
    if existing_project:
        raise HTTPException(status_code=400, detail="Project code already exists")
    
    # Set default billing settings based on billing model
    billing_settings = project.billing_settings or {}
    if project.billing_model == BillingModelEnum.HOURLY and not billing_settings:
        billing_settings = {"client_rate": 150.00, "min_increment_min": 15}
    elif project.billing_model == BillingModelEnum.FIXED and not billing_settings:
        billing_settings = {"fixed_price": 10000.00, "billing_schedule": "ON_ACCEPTANCE"}
    
    db_project = Project(
        id=uuid.uuid4(),
        org_id=org.id,
        billing_settings=billing_settings,
        **project.dict(exclude={"billing_settings"})
    )
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(project_id: UUID, db: Session = Depends(get_db)):
    """
    Get a specific project by ID.
    """
    # TODO: Add org scope check from auth context
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return project

@router.patch("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: UUID,
    project_update: ProjectUpdate,
    db: Session = Depends(get_db)
):
    """
    Update a project's information.
    """
    # TODO: Add org scope check from auth context
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    update_data = project_update.dict(exclude_unset=True)
    
    # Check code uniqueness if code is being updated
    if "code" in update_data:
        existing_project = db.query(Project).filter(
            Project.org_id == project.org_id,
            Project.code == update_data["code"],
            Project.id != project_id
        ).first()
        if existing_project:
            raise HTTPException(status_code=400, detail="Project code already exists")
    
    for field, value in update_data.items():
        setattr(project, field, value)
    
    db.commit()
    db.refresh(project)
    return project

@router.delete("/{project_id}")
async def delete_project(project_id: UUID, db: Session = Depends(get_db)):
    """
    Delete a project. Only allowed if no time entries or tasks exist for this project.
    """
    # TODO: Add org scope check from auth context
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    # Check if project has any tasks or time entries
    from app.db.models import Task, TimeEntry
    task_count = db.query(Task).filter(Task.project_id == project_id).count()
    time_entry_count = db.query(TimeEntry).filter(TimeEntry.project_id == project_id).count()
    
    if task_count > 0 or time_entry_count > 0:
        raise HTTPException(
            status_code=400, 
            detail=f"Cannot delete project with {task_count} tasks and {time_entry_count} time entries"
        )
    
    db.delete(project)
    db.commit()
    return {"message": "Project deleted successfully"}