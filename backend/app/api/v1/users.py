from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models.users import User, UserRole
from app.core.deps import get_current_active_user, get_current_org, require_admin, require_manager
from app.core.security import hash_password
from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime
from uuid import UUID

router = APIRouter()

class UserBase(BaseModel):
    email: EmailStr
    name: str
    status: str = "ACTIVE"

class UserCreate(UserBase):
    password: str
    roles: List[str] = ["CONTRACTOR"]

class UserUpdate(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None
    roles: Optional[List[str]] = None

class UserResponse(UserBase):
    id: UUID
    org_id: UUID
    created_at: datetime
    last_login_at: Optional[datetime] = None
    roles: List[str]

    class Config:
        from_attributes = True

class UserListResponse(BaseModel):
    id: UUID
    email: str
    name: str
    status: str
    roles: List[str]
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True

@router.get("/me", response_model=UserResponse)
async def get_current_user(current_user: User = Depends(get_current_active_user)):
    """Get current authenticated user"""
    user_roles = [role.role for role in current_user.roles]

    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        name=current_user.name,
        status=current_user.status,
        org_id=current_user.org_id,
        created_at=current_user.created_at,
        last_login_at=current_user.last_login_at,
        roles=user_roles
    )

@router.get("/", response_model=List[UserListResponse])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """List all users in the organization (requires MANAGER or ADMIN role)"""
    users = (
        db.query(User)
        .filter(User.org_id == current_user.org_id)
        .offset(skip)
        .limit(limit)
        .all()
    )

    result = []
    for user in users:
        user_roles = [role.role for role in user.roles]
        result.append(UserListResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            status=user.status,
            created_at=user.created_at,
            last_login_at=user.last_login_at,
            roles=user_roles
        ))

    return result

@router.post("/", response_model=UserResponse)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Create a new user (requires ADMIN role)"""
    # Check if user already exists
    existing_user = db.query(User).filter(
        User.email == user_data.email.lower(),
        User.org_id == current_user.org_id
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )

    # Create new user
    new_user = User(
        email=user_data.email.lower(),
        name=user_data.name,
        status=user_data.status,
        org_id=current_user.org_id,
        hashed_password=hash_password(user_data.password)
    )

    db.add(new_user)
    db.flush()  # Get the user ID

    # Add roles
    for role_name in user_data.roles:
        user_role = UserRole(
            org_id=current_user.org_id,
            user_id=new_user.id,
            role=role_name
        )
        db.add(user_role)

    db.commit()
    db.refresh(new_user)

    return UserResponse(
        id=new_user.id,
        email=new_user.email,
        name=new_user.name,
        status=new_user.status,
        org_id=new_user.org_id,
        created_at=new_user.created_at,
        last_login_at=new_user.last_login_at,
        roles=user_data.roles
    )

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Get a specific user by ID (requires MANAGER or ADMIN role)"""
    user = db.query(User).filter(
        User.id == user_id,
        User.org_id == current_user.org_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    user_roles = [role.role for role in user.roles]

    return UserResponse(
        id=user.id,
        email=user.email,
        name=user.name,
        status=user.status,
        org_id=user.org_id,
        created_at=user.created_at,
        last_login_at=user.last_login_at,
        roles=user_roles
    )

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    user_data: UserUpdate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """Update a user (requires ADMIN role)"""
    user = db.query(User).filter(
        User.id == user_id,
        User.org_id == current_user.org_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Update user fields
    if user_data.name is not None:
        user.name = user_data.name
    if user_data.status is not None:
        user.status = user_data.status

    # Update roles if provided
    if user_data.roles is not None:
        # Remove existing roles
        db.query(UserRole).filter(UserRole.user_id == user_id).delete()

        # Add new roles
        for role_name in user_data.roles:
            user_role = UserRole(
                org_id=current_user.org_id,
                user_id=user.id,
                role=role_name
            )
            db.add(user_role)

    db.commit()
    db.refresh(user)

    # Get updated roles
    user_roles = [role.role for role in user.roles]

    return UserResponse(
        id=user.id,
        email=user.email,
        name=user.name,
        status=user.status,
        org_id=user.org_id,
        created_at=user.created_at,
        last_login_at=user.last_login_at,
        roles=user_roles
    )