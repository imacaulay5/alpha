from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models.billing_rules import BillingRule, ScopeEnum
from app.db.models.users import User
from app.core.deps import get_current_active_user, require_manager
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from uuid import UUID
import uuid

router = APIRouter()

class BillingRuleBase(BaseModel):
    scope: ScopeEnum
    scope_id: Optional[UUID] = None
    priority: int = 100
    rule: Dict[str, Any]
    active: bool = True

class BillingRuleCreate(BillingRuleBase):
    pass

class BillingRuleUpdate(BaseModel):
    scope: Optional[ScopeEnum] = None
    scope_id: Optional[UUID] = None
    priority: Optional[int] = None
    rule: Optional[Dict[str, Any]] = None
    active: Optional[bool] = None

class BillingRuleResponse(BillingRuleBase):
    id: UUID
    org_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True

class RuleTestRequest(BaseModel):
    context: Dict[str, Any]

class RuleTestResponse(BaseModel):
    rate: float
    min_increment_min: Optional[int] = None
    overtime_multiplier: Optional[float] = None
    materials_markup_pct: Optional[float] = None
    applied_rules: List[Dict[str, Any]] = []

@router.get("/", response_model=List[BillingRuleResponse])
async def list_billing_rules(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    scope: Optional[ScopeEnum] = Query(None),
    scope_id: Optional[UUID] = Query(None),
    active: Optional[bool] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    List billing rules for the current organization.
    """
    query = db.query(BillingRule).filter(BillingRule.org_id == current_user.org_id)

    # Apply filters
    if scope:
        query = query.filter(BillingRule.scope == scope)
    if scope_id:
        query = query.filter(BillingRule.scope_id == scope_id)
    if active is not None:
        query = query.filter(BillingRule.active == active)

    # Order by priority (lower number = higher priority)
    query = query.order_by(BillingRule.priority.asc())

    rules = query.offset(skip).limit(limit).all()
    return rules

@router.post("/", response_model=BillingRuleResponse)
async def create_billing_rule(
    rule_data: BillingRuleCreate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Create a new billing rule (requires MANAGER or ADMIN role).
    """
    # Validate rule structure
    try:
        _validate_rule_structure(rule_data.rule)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid rule structure: {str(e)}"
        )

    # Create billing rule
    db_rule = BillingRule(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        scope=rule_data.scope,
        scope_id=rule_data.scope_id,
        priority=rule_data.priority,
        rule=rule_data.rule,
        active=rule_data.active
    )

    db.add(db_rule)
    db.commit()
    db.refresh(db_rule)
    return db_rule

@router.get("/{rule_id}", response_model=BillingRuleResponse)
async def get_billing_rule(
    rule_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific billing rule by ID.
    """
    rule = db.query(BillingRule).filter(
        BillingRule.id == rule_id,
        BillingRule.org_id == current_user.org_id
    ).first()

    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Billing rule not found"
        )

    return rule

@router.patch("/{rule_id}", response_model=BillingRuleResponse)
async def update_billing_rule(
    rule_id: UUID,
    rule_update: BillingRuleUpdate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Update a billing rule (requires MANAGER or ADMIN role).
    """
    rule = db.query(BillingRule).filter(
        BillingRule.id == rule_id,
        BillingRule.org_id == current_user.org_id
    ).first()

    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Billing rule not found"
        )

    update_data = rule_update.dict(exclude_unset=True)

    # Validate rule structure if being updated
    if "rule" in update_data:
        try:
            _validate_rule_structure(update_data["rule"])
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid rule structure: {str(e)}"
            )

    # Update fields
    for field, value in update_data.items():
        setattr(rule, field, value)

    db.commit()
    db.refresh(rule)
    return rule

@router.delete("/{rule_id}")
async def delete_billing_rule(
    rule_id: UUID,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Delete a billing rule (requires MANAGER or ADMIN role).
    """
    rule = db.query(BillingRule).filter(
        BillingRule.id == rule_id,
        BillingRule.org_id == current_user.org_id
    ).first()

    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Billing rule not found"
        )

    db.delete(rule)
    db.commit()
    return {"message": "Billing rule deleted successfully"}

@router.post("/test", response_model=RuleTestResponse)
async def test_billing_rules(
    test_request: RuleTestRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Test billing rules evaluation with a given context.
    """
    from app.services.pricing_engine import pricing_engine

    # Add org_id to context
    context = test_request.context.copy()
    context["org_id"] = str(current_user.org_id)

    try:
        result = pricing_engine.evaluate_pricing(context, db)
        return RuleTestResponse(**result)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error evaluating rules: {str(e)}"
        )

def _validate_rule_structure(rule: Dict[str, Any]) -> None:
    """
    Validate the structure of a billing rule.
    """
    required_fields = ["name"]
    if not all(field in rule for field in required_fields):
        raise ValueError(f"Missing required fields: {required_fields}")

    # Validate conditions if present
    if "conditions" in rule:
        conditions = rule["conditions"]
        if not isinstance(conditions, dict):
            raise ValueError("Conditions must be a dictionary")

    # Validate effects if present
    if "effects" in rule:
        effects = rule["effects"]
        if not isinstance(effects, dict):
            raise ValueError("Effects must be a dictionary")

        # Validate effect operations
        for effect_key, effect_value in effects.items():
            if isinstance(effect_value, dict) and "op" in effect_value:
                valid_ops = ["set", "multiply", "add"]
                if effect_value["op"] not in valid_ops:
                    raise ValueError(f"Invalid operation '{effect_value['op']}' for effect '{effect_key}'. Valid operations: {valid_ops}")

    # Validate date range if present
    if "active_date_range" in rule:
        date_range = rule["active_date_range"]
        if not isinstance(date_range, dict):
            raise ValueError("active_date_range must be a dictionary")
        if "from" in date_range:
            try:
                datetime.strptime(date_range["from"], "%Y-%m-%d")
            except ValueError:
                raise ValueError("active_date_range.from must be in YYYY-MM-DD format")
        if "to" in date_range and date_range["to"]:
            try:
                datetime.strptime(date_range["to"], "%Y-%m-%d")
            except ValueError:
                raise ValueError("active_date_range.to must be in YYYY-MM-DD format or null")
