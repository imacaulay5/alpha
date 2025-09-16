from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models.clients import Client
from app.db.models.users import User
from app.core.deps import get_current_active_user, require_manager
from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any
from datetime import datetime
from uuid import UUID
import uuid

router = APIRouter()

class ClientBase(BaseModel):
    name: str
    billing_contact_email: EmailStr
    terms: Optional[str] = None
    default_tax_profile: Optional[Dict[str, Any]] = None

class ClientCreate(ClientBase):
    pass

class ClientUpdate(BaseModel):
    name: Optional[str] = None
    billing_contact_email: Optional[EmailStr] = None
    terms: Optional[str] = None
    default_tax_profile: Optional[Dict[str, Any]] = None

class ClientResponse(ClientBase):
    id: UUID
    org_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True

@router.get("/", response_model=List[ClientResponse])
async def list_clients(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    search: Optional[str] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    List clients for the current organization with optional search.
    """
    query = db.query(Client).filter(Client.org_id == current_user.org_id)

    if search:
        query = query.filter(Client.name.ilike(f"%{search}%"))

    clients = query.offset(skip).limit(limit).all()
    return clients

@router.post("/", response_model=ClientResponse)
async def create_client(
    client_data: ClientCreate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Create a new client for the current organization (requires MANAGER or ADMIN role).
    """
    # Check if client name already exists in org
    existing_client = db.query(Client).filter(
        Client.org_id == current_user.org_id,
        Client.name == client_data.name
    ).first()
    if existing_client:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Client name already exists"
        )

    db_client = Client(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        **client_data.dict()
    )
    db.add(db_client)
    db.commit()
    db.refresh(db_client)
    return db_client

@router.get("/{client_id}", response_model=ClientResponse)
async def get_client(
    client_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific client by ID within the current organization.
    """
    client = db.query(Client).filter(
        Client.id == client_id,
        Client.org_id == current_user.org_id
    ).first()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    return client

@router.patch("/{client_id}", response_model=ClientResponse)
async def update_client(
    client_id: UUID,
    client_update: ClientUpdate,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Update a client's information (requires MANAGER or ADMIN role).
    """
    client = db.query(Client).filter(
        Client.id == client_id,
        Client.org_id == current_user.org_id
    ).first()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )

    update_data = client_update.dict(exclude_unset=True)

    # Check name uniqueness if name is being updated
    if "name" in update_data:
        existing_client = db.query(Client).filter(
            Client.org_id == current_user.org_id,
            Client.name == update_data["name"],
            Client.id != client_id
        ).first()
        if existing_client:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Client name already exists"
            )

    for field, value in update_data.items():
        setattr(client, field, value)

    db.commit()
    db.refresh(client)
    return client

@router.delete("/{client_id}")
async def delete_client(
    client_id: UUID,
    current_user: User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """
    Delete a client (requires MANAGER or ADMIN role).
    Only allowed if no projects exist for this client.
    """
    client = db.query(Client).filter(
        Client.id == client_id,
        Client.org_id == current_user.org_id
    ).first()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )

    # Check if client has any projects
    from app.db.models.projects import Project
    project_count = db.query(Project).filter(Project.client_id == client_id).count()
    if project_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete client with {project_count} active projects"
        )

    db.delete(client)
    db.commit()
    return {"message": "Client deleted successfully"}