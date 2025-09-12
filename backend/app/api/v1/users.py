from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models import User
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from uuid import UUID

router = APIRouter()

class UserBase(BaseModel):
    email: str
    name: str
    status: str = "ACTIVE"

class UserCreate(UserBase):
    pass

class UserUpdate(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None

class UserResponse(UserBase):
    id: UUID
    org_id: UUID
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True

@router.get("/me", response_model=UserResponse)
async def get_current_user(db: Session = Depends(get_db)):
    # TODO: Get current user from auth context
    # For now, return the first admin user for testing
    user = db.query(User).filter(User.email == "admin@demo.com").first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/")
async def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    try:
        users = db.query(User).offset(skip).limit(limit).all()
        print(f"Found {len(users)} users")  # Debug
        return {"message": f"Found {len(users)} users", "count": len(users)}
    except Exception as e:
        print(f"Error in list_users: {e}")  # Debug
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # TODO: Implement user creation
    pass

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(user_id: str, user: UserUpdate, db: Session = Depends(get_db)):
    # TODO: Implement user update
    pass