from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models.tasks import Task, UOMEnum
from app.db.models.projects import Project
from app.db.models.users import User
from app.core.deps import get_current_active_user, require_manager
from pydantic import BaseModel
from typing import List, Optional
from decimal import Decimal
from uuid import UUID
import uuid

router = APIRouter()

class TaskBase(BaseModel):
    name: str
    category: str
    is_billable: bool = True
    default_rate: Decimal = Decimal('0.00')
    uom: UOMEnum = UOMEnum.HOUR

class TaskCreate(TaskBase):
    project_id: UUID

class TaskUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    is_billable: Optional[bool] = None
    default_rate: Optional[Decimal] = None
    uom: Optional[UOMEnum] = None

class TaskResponse(TaskBase):
    id: UUID
    org_id: UUID
    project_id: UUID

    class Config:
        from_attributes = True

class TaskListResponse(BaseModel):
    id: UUID
    project_id: UUID
    name: str
    category: str
    is_billable: bool
    default_rate: Decimal
    uom: UOMEnum

    # Related data for better UX
    project_name: Optional[str] = None

    class Config:
        from_attributes = True

@router.get("/", response_model=List[TaskListResponse])
async def list_tasks(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    project_id: Optional[UUID] = Query(None),
    category: Optional[str] = Query(None),
    is_billable: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    List tasks with filtering options.
    """
    query = db.query(Task).filter(Task.org_id == current_user.org_id)

    # Apply filters
    if project_id:
        query = query.filter(Task.project_id == project_id)
    if category:
        query = query.filter(Task.category == category)
    if is_billable is not None:
        query = query.filter(Task.is_billable == is_billable)
    if search:
        query = query.filter(Task.name.ilike(f"%{search}%"))

    # Join with project for better response
    query = query.join(Project)

    tasks = query.offset(skip).limit(limit).all()

    # Build response with related data
    result = []
    for task in tasks:
        result.append(TaskListResponse(
            id=task.id,
            project_id=task.project_id,
            name=task.name,
            category=task.category,
            is_billable=task.is_billable,
            default_rate=task.default_rate,
            uom=task.uom,
            project_name=task.project.name
        ))

    return result

@router.post("/", response_model=TaskResponse)
async def create_task(
    task_data: TaskCreate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Create a new task (requires MANAGER or ADMIN role).
    """
    # Verify project exists and belongs to the organization
    project = db.query(Project).filter(
        Project.id == task_data.project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    # Check if task name already exists in project
    existing_task = db.query(Task).filter(
        Task.project_id == task_data.project_id,
        Task.name == task_data.name
    ).first()
    if existing_task:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Task name already exists in this project"
        )

    # Create task
    db_task = Task(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        project_id=task_data.project_id,
        name=task_data.name,
        category=task_data.category,
        is_billable=task_data.is_billable,
        default_rate=task_data.default_rate,
        uom=task_data.uom
    )

    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific task by ID within the current organization.
    """
    task = db.query(Task).filter(
        Task.id == task_id,
        Task.org_id == current_user.org_id
    ).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    return task

@router.patch("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: UUID,
    task_update: TaskUpdate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Update a task's information (requires MANAGER or ADMIN role).
    """
    task = db.query(Task).filter(
        Task.id == task_id,
        Task.org_id == current_user.org_id
    ).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )

    update_data = task_update.dict(exclude_unset=True)

    # Check name uniqueness if name is being updated
    if "name" in update_data:
        existing_task = db.query(Task).filter(
            Task.project_id == task.project_id,
            Task.name == update_data["name"],
            Task.id != task_id
        ).first()
        if existing_task:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Task name already exists in this project"
            )

    # Update fields
    for field, value in update_data.items():
        setattr(task, field, value)

    db.commit()
    db.refresh(task)
    return task

@router.delete("/{task_id}")
async def delete_task(
    task_id: UUID,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Delete a task (requires MANAGER or ADMIN role).
    Only allowed if no time entries exist for this task.
    """
    task = db.query(Task).filter(
        Task.id == task_id,
        Task.org_id == current_user.org_id
    ).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )

    # Check if task has any time entries
    from app.db.models.time_entries import TimeEntry
    time_entry_count = db.query(TimeEntry).filter(TimeEntry.task_id == task_id).count()
    if time_entry_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete task with {time_entry_count} time entries"
        )

    # Check if task has any expenses
    from app.db.models.expenses import Expense
    expense_count = db.query(Expense).filter(Expense.task_id == task_id).count()
    if expense_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete task with {expense_count} expenses"
        )

    db.delete(task)
    db.commit()
    return {"message": "Task deleted successfully"}

@router.get("/categories/", response_model=List[str])
async def get_task_categories(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get all unique task categories in the organization.
    """
    categories = db.query(Task.category).filter(
        Task.org_id == current_user.org_id
    ).distinct().all()

    return [category[0] for category in categories if category[0]]

@router.get("/project/{project_id}", response_model=List[TaskResponse])
async def get_project_tasks(
    project_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get all tasks for a specific project.
    """
    # Verify project exists and user has access
    project = db.query(Project).filter(
        Project.id == project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    tasks = db.query(Task).filter(
        Task.project_id == project_id,
        Task.org_id == current_user.org_id
    ).all()

    return tasks