from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List

from app.db.session import get_db
from app.db.models.users import User
from app.core.security import verify_password, create_access_token
from app.core.deps import get_current_active_user
from app.core.config import settings
from pydantic import BaseModel, EmailStr

router = APIRouter()

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    user: "UserProfile"

class UserProfile(BaseModel):
    id: str
    email: str
    name: str
    org_id: str
    status: str
    roles: List[str]

    class Config:
        from_attributes = True

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

@router.post("/login", response_model=TokenResponse)
async def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user and return access token
    """
    # Find user by email
    user = db.query(User).filter(User.email == login_data.email.lower()).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    # Verify password
    if not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    # Check if user is active
    if user.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account is not active"
        )

    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )

    # Get user roles
    user_roles = [role.role for role in user.roles]

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,  # Convert to seconds
        user=UserProfile(
            id=str(user.id),
            email=user.email,
            name=user.name,
            org_id=str(user.org_id),
            status=user.status,
            roles=user_roles
        )
    )

@router.get("/me", response_model=UserProfile)
async def get_current_user(current_user: User = Depends(get_current_active_user)):
    """
    Get current user profile
    """
    user_roles = [role.role for role in current_user.roles]

    return UserProfile(
        id=str(current_user.id),
        email=current_user.email,
        name=current_user.name,
        org_id=str(current_user.org_id),
        status=current_user.status,
        roles=user_roles
    )

@router.post("/change-password")
async def change_password(
    password_data: ChangePasswordRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Change user password
    """
    # Verify current password
    if not verify_password(password_data.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )

    # Update password
    from app.core.security import hash_password
    current_user.hashed_password = hash_password(password_data.new_password)
    db.commit()

    return {"message": "Password changed successfully"}

@router.post("/logout")
async def logout(current_user: User = Depends(get_current_active_user)):
    """
    Logout user (client should delete token)
    """
    return {"message": "Logged out successfully"}