from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import jwt, JWTError

from app.core.config import settings
from app.core.security import verify_token
from app.db.session import get_db
from app.db.models.users import User
from app.db.models.organizations import Organization

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """
    Get the current authenticated user from JWT token
    """
    try:
        payload = verify_token(credentials.credentials)
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """
    Get the current active user (check if user is not disabled)
    """
    if current_user.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    return current_user

async def get_current_org(current_user: User = Depends(get_current_active_user)) -> Organization:
    """
    Get the current user's organization
    """
    if not current_user.organization:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User has no organization"
        )
    return current_user.organization

def require_roles(*allowed_roles: str):
    """
    Dependency factory to require specific roles
    Usage: @app.get("/admin", dependencies=[Depends(require_roles("ADMIN"))])
    """
    def role_checker(current_user: User = Depends(get_current_active_user)):
        user_roles = [role.role for role in current_user.roles]
        if not any(role in user_roles for role in allowed_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation requires one of: {', '.join(allowed_roles)}"
            )
        return current_user
    return role_checker

# Common role dependencies
require_admin = require_roles("ADMIN")
require_manager = require_roles("ADMIN", "MANAGER")
require_contractor = require_roles("ADMIN", "MANAGER", "CONTRACTOR")