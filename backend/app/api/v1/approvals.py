from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from app.db.session import get_db
from app.db.models.approvals import Approval, ItemTypeEnum, DecisionEnum
from app.db.models.time_entries import TimeEntry, StatusEnum
from app.db.models.expenses import Expense
from app.db.models.users import User
from app.db.models.projects import Project
from app.db.models.tasks import Task
from app.core.deps import get_current_active_user, require_manager
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
from uuid import UUID
import uuid

router = APIRouter()

class ApprovalItemResponse(BaseModel):
    id: str
    type: str
    user_name: str
    user_email: str
    project_name: Optional[str] = None
    task_name: Optional[str] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    amount: float
    notes: Optional[str] = None
    description: Optional[str] = None
    submitted_at: datetime
    receipt_url: Optional[str] = None

    # For recent decisions
    decision: Optional[str] = None
    decided_at: Optional[datetime] = None
    decided_by: Optional[str] = None
    comment: Optional[str] = None

class DecisionRequest(BaseModel):
    decision: DecisionEnum
    comment: Optional[str] = None

@router.get("/", response_model=List[ApprovalItemResponse])
async def list_pending_approvals(
    type: Optional[ItemTypeEnum] = Query(None),
    status: str = Query("pending", description="'pending' or 'recent'"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    List items pending approval or recent approval decisions.
    Requires MANAGER or ADMIN role.
    """
    result = []

    if status == "pending":
        # Get pending time entries
        if not type or type == ItemTypeEnum.TIME:
            time_entries = db.query(TimeEntry).filter(
                TimeEntry.org_id == current_user.org_id,
                TimeEntry.status == StatusEnum.SUBMITTED
            ).all()

            for entry in time_entries:
                # Get related data
                user = db.query(User).filter(User.id == entry.user_id).first()
                project = db.query(Project).filter(Project.id == entry.project_id).first()
                task = db.query(Task).filter(Task.id == entry.task_id).first()

                # Calculate amount (placeholder - should use billing rules)
                rate = 150.0  # Default rate
                hours = entry.duration_minutes / 60
                amount = hours * rate

                result.append(ApprovalItemResponse(
                    id=str(entry.id),
                    type="TIME",
                    user_name=user.name if user else "Unknown",
                    user_email=user.email if user else "",
                    project_name=project.name if project else None,
                    task_name=task.name if task else None,
                    start_at=entry.start_at,
                    end_at=entry.end_at,
                    duration_minutes=entry.duration_minutes,
                    amount=amount,
                    notes=entry.notes,
                    submitted_at=entry.created_at or datetime.now()
                ))

        # Get pending expenses
        if not type or type == ItemTypeEnum.EXPENSE:
            expenses = db.query(Expense).filter(
                Expense.org_id == current_user.org_id,
                Expense.status == StatusEnum.SUBMITTED
            ).all()

            for expense in expenses:
                # Get related data
                user = db.query(User).filter(User.id == expense.user_id).first()
                project = db.query(Project).filter(Project.id == expense.project_id).first()

                result.append(ApprovalItemResponse(
                    id=str(expense.id),
                    type="EXPENSE",
                    user_name=user.name if user else "Unknown",
                    user_email=user.email if user else "",
                    project_name=project.name if project else None,
                    amount=float(expense.amount),
                    description=expense.notes,
                    submitted_at=expense.created_at or datetime.now(),
                    receipt_url=expense.receipt_url
                ))

    else:  # status == "recent"
        # Get recent approval decisions
        recent_approvals = db.query(Approval).filter(
            Approval.org_id == current_user.org_id
        ).order_by(Approval.decided_at.desc()).limit(limit).all()

        for approval in recent_approvals:
            approver = db.query(User).filter(User.id == approval.approver_user_id).first()

            if approval.item_type == ItemTypeEnum.TIME:
                time_entry = db.query(TimeEntry).filter(TimeEntry.id == approval.item_id).first()
                if time_entry:
                    user = db.query(User).filter(User.id == time_entry.user_id).first()
                    project = db.query(Project).filter(Project.id == time_entry.project_id).first()
                    task = db.query(Task).filter(Task.id == time_entry.task_id).first()

                    # Calculate amount
                    rate = 150.0
                    hours = time_entry.duration_minutes / 60
                    amount = hours * rate

                    result.append(ApprovalItemResponse(
                        id=str(time_entry.id),
                        type="TIME",
                        user_name=user.name if user else "Unknown",
                        user_email=user.email if user else "",
                        project_name=project.name if project else None,
                        task_name=task.name if task else None,
                        duration_minutes=time_entry.duration_minutes,
                        amount=amount,
                        notes=time_entry.notes,
                        submitted_at=time_entry.created_at or datetime.now(),
                        decision=approval.decision.value,
                        decided_at=approval.decided_at,
                        decided_by=approver.name if approver else "Unknown",
                        comment=approval.comment
                    ))

            elif approval.item_type == ItemTypeEnum.EXPENSE:
                expense = db.query(Expense).filter(Expense.id == approval.item_id).first()
                if expense:
                    user = db.query(User).filter(User.id == expense.user_id).first()
                    project = db.query(Project).filter(Project.id == expense.project_id).first()

                    result.append(ApprovalItemResponse(
                        id=str(expense.id),
                        type="EXPENSE",
                        user_name=user.name if user else "Unknown",
                        user_email=user.email if user else "",
                        project_name=project.name if project else None,
                        amount=float(expense.amount),
                        description=expense.notes,
                        submitted_at=expense.created_at or datetime.now(),
                        decision=approval.decision.value,
                        decided_at=approval.decided_at,
                        decided_by=approver.name if approver else "Unknown",
                        comment=approval.comment
                    ))

    # Apply pagination
    return result[skip:skip + limit]

@router.post("/{item_type}/{item_id}/decision")
async def make_approval_decision(
    item_type: ItemTypeEnum,
    item_id: UUID,
    decision_data: DecisionRequest,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Make an approval decision on a time entry or expense.
    Requires MANAGER or ADMIN role.
    """
    if item_type == ItemTypeEnum.TIME:
        # Get time entry
        item = db.query(TimeEntry).filter(
            TimeEntry.id == item_id,
            TimeEntry.org_id == current_user.org_id
        ).first()

        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Time entry not found"
            )

        if item.status != StatusEnum.SUBMITTED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only submitted time entries can be approved/rejected"
            )

        # Update time entry status
        if decision_data.decision == DecisionEnum.APPROVE:
            item.status = StatusEnum.APPROVED
            message = "Time entry approved"
        else:
            item.status = StatusEnum.REJECTED
            message = "Time entry rejected"

        item.approved_by = current_user.id
        item.approved_at = datetime.now()

    elif item_type == ItemTypeEnum.EXPENSE:
        # Get expense
        item = db.query(Expense).filter(
            Expense.id == item_id,
            Expense.org_id == current_user.org_id
        ).first()

        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Expense not found"
            )

        if item.status != StatusEnum.SUBMITTED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only submitted expenses can be approved/rejected"
            )

        # Update expense status
        if decision_data.decision == DecisionEnum.APPROVE:
            item.status = StatusEnum.APPROVED
            message = "Expense approved"
        else:
            item.status = StatusEnum.REJECTED
            message = "Expense rejected"

        item.approved_by = current_user.id
        item.approved_at = datetime.now()

    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported item type for approval"
        )

    # Create approval record
    approval = Approval(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        item_type=item_type,
        item_id=item_id,
        approver_user_id=current_user.id,
        decision=decision_data.decision,
        comment=decision_data.comment
    )
    db.add(approval)

    db.commit()

    return {"message": message}
