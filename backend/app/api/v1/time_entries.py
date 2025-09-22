from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.db.session import get_db
from app.db.models.time_entries import TimeEntry, StatusEnum, SourceEnum
from app.db.models.projects import Project
from app.db.models.tasks import Task
from app.db.models.users import User
from app.core.deps import get_current_active_user, require_manager
from app.services.pricing_engine import pricing_engine
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta, timezone
from uuid import UUID
from decimal import Decimal
import uuid

router = APIRouter()

class TimeEntryBase(BaseModel):
    project_id: UUID
    task_id: UUID
    start_at: datetime
    end_at: Optional[datetime] = None
    duration_minutes: int
    notes: Optional[str] = None
    geo: Optional[Dict[str, Any]] = None
    source: SourceEnum = SourceEnum.WEB

class TimeEntryCreate(TimeEntryBase):
    pass

class TimeEntryUpdate(BaseModel):
    project_id: Optional[UUID] = None
    task_id: Optional[UUID] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    notes: Optional[str] = None
    geo: Optional[Dict[str, Any]] = None
    source: Optional[SourceEnum] = None
    status: Optional[StatusEnum] = None

class TimeEntryResponse(TimeEntryBase):
    id: UUID
    org_id: UUID
    user_id: UUID
    status: StatusEnum
    approved_by: Optional[UUID] = None
    approved_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class TimeEntryListResponse(BaseModel):
    id: UUID
    project_id: UUID
    task_id: UUID
    start_at: datetime
    end_at: Optional[datetime] = None
    duration_minutes: int
    notes: Optional[str] = None
    status: StatusEnum
    source: SourceEnum
    created_at: Optional[datetime] = None

    # Related data for better UX
    project_name: Optional[str] = None
    task_name: Optional[str] = None
    user_name: Optional[str] = None

    # Calculated pricing fields
    calculated_rate: Optional[float] = None
    calculated_amount: Optional[float] = None

    class Config:
        from_attributes = True

class ApprovalRequest(BaseModel):
    decision: str  # "APPROVE" or "REJECT"
    comment: Optional[str] = None

def _calculate_time_entry_pricing(time_entry: TimeEntry, db: Session) -> Dict[str, Any]:
    """Calculate pricing for a time entry using the pricing engine."""

    # Build context for pricing engine
    context = {
        "org_id": str(time_entry.org_id),
        "client_id": str(time_entry.project.client_id) if time_entry.project else None,
        "project_id": str(time_entry.project_id),
        "task_id": str(time_entry.task_id),
        "contractor_user_id": str(time_entry.user_id),
        "start_at": time_entry.start_at.isoformat() if time_entry.start_at else None,
        "duration_minutes": time_entry.duration_minutes,
        "source": time_entry.source.value if time_entry.source else None,
        "geo": time_entry.geo
    }

    # Add task category if available
    if time_entry.task:
        context["task_category"] = time_entry.task.category

    try:
        # Evaluate pricing using the pricing engine
        pricing_result = pricing_engine.evaluate_pricing(context, db)

        # Calculate amount based on duration and rate
        hours = Decimal(time_entry.duration_minutes) / Decimal('60')
        rate = Decimal(str(pricing_result['rate']))
        amount = hours * rate

        return {
            "calculated_rate": float(rate),
            "calculated_amount": float(amount),
            "pricing_context": context,
            "applied_rules": pricing_result.get("applied_rules", [])
        }

    except Exception as e:
        # Fallback to base rate if pricing engine fails
        print(f"Error calculating pricing for time entry {time_entry.id}: {e}")

        # Get base rate
        base_rate = pricing_engine.get_base_rate(
            task_id=time_entry.task_id,
            user_id=time_entry.user_id,
            db=db
        )

        hours = Decimal(time_entry.duration_minutes) / Decimal('60')
        amount = hours * base_rate

        return {
            "calculated_rate": float(base_rate),
            "calculated_amount": float(amount),
            "pricing_context": context,
            "applied_rules": []
        }

@router.get("/", response_model=List[TimeEntryListResponse])
async def list_time_entries(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    project_id: Optional[UUID] = Query(None),
    task_id: Optional[UUID] = Query(None),
    user_id: Optional[UUID] = Query(None),
    status: Optional[StatusEnum] = Query(None),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    List time entries with filtering options.
    Regular users see only their own entries, managers see all in organization.
    """
    query = db.query(TimeEntry).filter(TimeEntry.org_id == current_user.org_id)

    # Regular users can only see their own time entries
    user_roles = [role.role for role in current_user.roles]
    if not any(role in ["ADMIN", "MANAGER"] for role in user_roles):
        query = query.filter(TimeEntry.user_id == current_user.id)
    elif user_id:
        # Managers can filter by specific user
        query = query.filter(TimeEntry.user_id == user_id)

    # Apply filters
    if project_id:
        query = query.filter(TimeEntry.project_id == project_id)
    if task_id:
        query = query.filter(TimeEntry.task_id == task_id)
    if status:
        query = query.filter(TimeEntry.status == status)
    if start_date:
        query = query.filter(TimeEntry.start_at >= start_date)
    if end_date:
        query = query.filter(TimeEntry.start_at <= end_date)

    time_entries = query.offset(skip).limit(limit).all()

    # Build response with related data
    result = []
    for entry in time_entries:
        # Get related data separately to avoid join issues
        project = db.query(Project).filter(Project.id == entry.project_id).first()
        task = db.query(Task).filter(Task.id == entry.task_id).first()
        user = db.query(User).filter(User.id == entry.user_id).first()

        result.append(TimeEntryListResponse(
            id=entry.id,
            project_id=entry.project_id,
            task_id=entry.task_id,
            start_at=entry.start_at,
            end_at=entry.end_at,
            duration_minutes=entry.duration_minutes,
            notes=entry.notes,
            status=entry.status,
            source=entry.source,
            created_at=getattr(entry, 'created_at', None),
            project_name=project.name if project else None,
            task_name=task.name if task else None,
            user_name=user.name if user else None,
            calculated_rate=float(entry.calculated_rate) if entry.calculated_rate else None,
            calculated_amount=float(entry.calculated_amount) if entry.calculated_amount else None
        ))

    return result

@router.post("/", response_model=TimeEntryResponse)
async def create_time_entry(
    time_entry_data: TimeEntryCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Create a new time entry for the current user.
    """
    # Verify project exists and user has access
    project = db.query(Project).filter(
        Project.id == time_entry_data.project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    # Verify task exists and belongs to the project
    task = db.query(Task).filter(
        Task.id == time_entry_data.task_id,
        Task.project_id == time_entry_data.project_id,
        Task.org_id == current_user.org_id
    ).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found or doesn't belong to the specified project"
        )

    # Validate duration makes sense
    if time_entry_data.duration_minutes <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Duration must be greater than 0"
        )

    # Auto-calculate end_at if not provided
    end_at = time_entry_data.end_at
    if not end_at and time_entry_data.duration_minutes:
        end_at = time_entry_data.start_at + timedelta(minutes=time_entry_data.duration_minutes)

    # Create time entry
    db_time_entry = TimeEntry(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        user_id=current_user.id,
        project_id=time_entry_data.project_id,
        task_id=time_entry_data.task_id,
        start_at=time_entry_data.start_at,
        end_at=end_at,
        duration_minutes=time_entry_data.duration_minutes,
        notes=time_entry_data.notes,
        geo=time_entry_data.geo,
        source=time_entry_data.source,
        status=StatusEnum.DRAFT
    )

    db.add(db_time_entry)
    db.flush()  # Get the ID before calculating pricing

    # Load related objects for pricing calculation
    db_time_entry.project = project
    db_time_entry.task = task

    # Calculate pricing using the pricing engine
    try:
        pricing_data = _calculate_time_entry_pricing(db_time_entry, db)
        db_time_entry.calculated_rate = Decimal(str(pricing_data["calculated_rate"]))
        db_time_entry.calculated_amount = Decimal(str(pricing_data["calculated_amount"]))
        db_time_entry.pricing_context = pricing_data["pricing_context"]
        db_time_entry.applied_rules = pricing_data["applied_rules"]
    except Exception as e:
        print(f"Warning: Failed to calculate pricing for time entry: {e}")
        # Continue without pricing data

    db.commit()
    db.refresh(db_time_entry)
    return db_time_entry

@router.get("/{time_entry_id}", response_model=TimeEntryResponse)
async def get_time_entry(
    time_entry_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific time entry by ID.
    Users can only access their own entries unless they're managers.
    """
    query = db.query(TimeEntry).filter(
        TimeEntry.id == time_entry_id,
        TimeEntry.org_id == current_user.org_id
    )

    # Regular users can only see their own time entries
    user_roles = [role.role for role in current_user.roles]
    if not any(role in ["ADMIN", "MANAGER"] for role in user_roles):
        query = query.filter(TimeEntry.user_id == current_user.id)

    time_entry = query.first()
    if not time_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Time entry not found"
        )

    return time_entry

@router.patch("/{time_entry_id}", response_model=TimeEntryResponse)
async def update_time_entry(
    time_entry_id: UUID,
    time_entry_update: TimeEntryUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Update a time entry. Users can only update their own entries.
    Only draft entries can be modified by users.
    """
    time_entry = db.query(TimeEntry).filter(
        TimeEntry.id == time_entry_id,
        TimeEntry.org_id == current_user.org_id,
        TimeEntry.user_id == current_user.id
    ).first()

    if not time_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Time entry not found"
        )

    # Only allow updates to draft entries unless user is manager
    user_roles = [role.role for role in current_user.roles]
    is_manager = any(role in ["ADMIN", "MANAGER"] for role in user_roles)

    if not is_manager and time_entry.status != StatusEnum.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only draft time entries can be modified"
        )

    update_data = time_entry_update.dict(exclude_unset=True)

    # Validate project and task if being updated
    if "project_id" in update_data:
        project = db.query(Project).filter(
            Project.id == update_data["project_id"],
            Project.org_id == current_user.org_id
        ).first()
        if not project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Project not found"
            )

    if "task_id" in update_data:
        task_project_id = update_data.get("project_id", time_entry.project_id)
        task = db.query(Task).filter(
            Task.id == update_data["task_id"],
            Task.project_id == task_project_id,
            Task.org_id == current_user.org_id
        ).first()
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found or doesn't belong to the specified project"
            )

    # Update fields
    for field, value in update_data.items():
        setattr(time_entry, field, value)

    # Recalculate end_at if duration changed
    if "duration_minutes" in update_data and time_entry.start_at:
        time_entry.end_at = time_entry.start_at + timedelta(minutes=time_entry.duration_minutes)

    db.commit()
    db.refresh(time_entry)
    return time_entry

@router.post("/{time_entry_id}/submit")
async def submit_time_entry(
    time_entry_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Submit a time entry for approval.
    """
    time_entry = db.query(TimeEntry).filter(
        TimeEntry.id == time_entry_id,
        TimeEntry.org_id == current_user.org_id,
        TimeEntry.user_id == current_user.id
    ).first()

    if not time_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Time entry not found"
        )

    if time_entry.status != StatusEnum.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only draft time entries can be submitted"
        )

    time_entry.status = StatusEnum.SUBMITTED
    db.commit()

    return {"message": "Time entry submitted for approval"}

@router.post("/{time_entry_id}/approve")
async def approve_time_entry(
    time_entry_id: UUID,
    approval_data: ApprovalRequest,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Approve or reject a time entry (requires MANAGER or ADMIN role).
    """
    time_entry = db.query(TimeEntry).filter(
        TimeEntry.id == time_entry_id,
        TimeEntry.org_id == current_user.org_id
    ).first()

    if not time_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Time entry not found"
        )

    if time_entry.status != StatusEnum.SUBMITTED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only submitted time entries can be approved/rejected"
        )

    if approval_data.decision.upper() == "APPROVE":
        time_entry.status = StatusEnum.APPROVED
        message = "Time entry approved"
    elif approval_data.decision.upper() == "REJECT":
        time_entry.status = StatusEnum.REJECTED
        message = "Time entry rejected"
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Decision must be 'APPROVE' or 'REJECT'"
        )

    time_entry.approved_by = current_user.id
    time_entry.approved_at = datetime.now(timezone.utc)

    # Create approval record if needed (for audit trail)
    from app.db.models.approvals import Approval
    approval = Approval(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        item_type="TIME",
        item_id=time_entry.id,
        approver_user_id=current_user.id,
        decision=approval_data.decision.upper(),
        comment=approval_data.comment,
        decided_at=datetime.now(timezone.utc)
    )
    db.add(approval)

    db.commit()

    return {"message": message}

@router.delete("/{time_entry_id}")
async def delete_time_entry(
    time_entry_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Delete a time entry. Only draft entries can be deleted.
    """
    time_entry = db.query(TimeEntry).filter(
        TimeEntry.id == time_entry_id,
        TimeEntry.org_id == current_user.org_id,
        TimeEntry.user_id == current_user.id
    ).first()

    if not time_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Time entry not found"
        )

    if time_entry.status != StatusEnum.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only draft time entries can be deleted"
        )

    db.delete(time_entry)
    db.commit()

    return {"message": "Time entry deleted successfully"}

# Timer-related endpoints for real-time tracking

class TimerStartRequest(BaseModel):
    project_id: UUID
    task_id: UUID
    notes: Optional[str] = None

@router.post("/timer/start")
async def start_timer(
    timer_data: TimerStartRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Start a timer for a new time entry.
    """
    # Verify project and task exist
    project = db.query(Project).filter(
        Project.id == timer_data.project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    task = db.query(Task).filter(
        Task.id == timer_data.task_id,
        Task.project_id == timer_data.project_id,
        Task.org_id == current_user.org_id
    ).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )

    # Check if user already has a running timer
    active_timer = db.query(TimeEntry).filter(
        TimeEntry.user_id == current_user.id,
        TimeEntry.org_id == current_user.org_id,
        TimeEntry.end_at.is_(None),
        TimeEntry.status == StatusEnum.DRAFT
    ).first()

    if active_timer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have an active timer. Stop it before starting a new one."
        )

    # Create new timer entry
    timer_entry = TimeEntry(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        user_id=current_user.id,
        project_id=timer_data.project_id,
        task_id=timer_data.task_id,
        start_at=datetime.now(timezone.utc),
        end_at=None,
        duration_minutes=0,
        notes=timer_data.notes,
        source=SourceEnum.WEB,
        status=StatusEnum.DRAFT
    )

    db.add(timer_entry)
    db.commit()
    db.refresh(timer_entry)

    return {
        "message": "Timer started",
        "time_entry_id": timer_entry.id,
        "started_at": timer_entry.start_at
    }

@router.post("/timer/stop")
async def stop_timer(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Stop the currently running timer.
    """
    active_timer = db.query(TimeEntry).filter(
        TimeEntry.user_id == current_user.id,
        TimeEntry.org_id == current_user.org_id,
        TimeEntry.end_at.is_(None),
        TimeEntry.status == StatusEnum.DRAFT
    ).first()

    if not active_timer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active timer found"
        )

    # Calculate duration and stop timer
    end_time = datetime.now(timezone.utc)
    duration = end_time - active_timer.start_at
    duration_minutes = int(duration.total_seconds() / 60)

    active_timer.end_at = end_time
    active_timer.duration_minutes = duration_minutes

    # Calculate pricing now that we have duration
    try:
        pricing_data = _calculate_time_entry_pricing(active_timer, db)
        active_timer.calculated_rate = Decimal(str(pricing_data["calculated_rate"]))
        active_timer.calculated_amount = Decimal(str(pricing_data["calculated_amount"]))
        active_timer.pricing_context = pricing_data["pricing_context"]
        active_timer.applied_rules = pricing_data["applied_rules"]
    except Exception as e:
        print(f"Warning: Failed to calculate pricing for timer stop: {e}")

    db.commit()
    db.refresh(active_timer)

    return {
        "message": "Timer stopped",
        "time_entry_id": active_timer.id,
        "duration_minutes": duration_minutes,
        "stopped_at": end_time
    }

@router.get("/timer/status")
async def get_timer_status(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get the current timer status for the user.
    """
    active_timer = db.query(TimeEntry).filter(
        TimeEntry.user_id == current_user.id,
        TimeEntry.org_id == current_user.org_id,
        TimeEntry.end_at.is_(None),
        TimeEntry.status == StatusEnum.DRAFT
    ).first()

    if not active_timer:
        return {"active": False, "timer": None}

    # Calculate current duration
    current_time = datetime.now(timezone.utc)
    current_duration = current_time - active_timer.start_at
    current_duration_minutes = int(current_duration.total_seconds() / 60)

    return {
        "active": True,
        "timer": {
            "time_entry_id": active_timer.id,
            "project_id": active_timer.project_id,
            "task_id": active_timer.task_id,
            "started_at": active_timer.start_at,
            "current_duration_minutes": current_duration_minutes,
            "notes": active_timer.notes
        }
    }