from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date

router = APIRouter()

class ProjectBase(BaseModel):
    name: str
    code: str
    status: str = "ACTIVE"
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    notes: Optional[str] = None
    billing_model: str = "HOURLY"

class ProjectCreate(ProjectBase):
    client_id: str

class ProjectResponse(ProjectBase):
    id: str
    org_id: str
    client_id: str
    
    class Config:
        from_attributes = True

@router.get("/", response_model=List[ProjectResponse])
async def list_projects(db: Session = Depends(get_db)):
    # TODO: Implement project listing
    pass

@router.post("/", response_model=ProjectResponse)
async def create_project(project: ProjectCreate, db: Session = Depends(get_db)):
    # TODO: Implement project creation
    pass