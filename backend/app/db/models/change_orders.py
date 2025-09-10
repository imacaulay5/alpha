from sqlalchemy import Column, String, ForeignKey, Numeric, Text, DateTime, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class ChangeOrderStatusEnum(str, enum.Enum):
    DRAFT = "DRAFT"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"

class ChangeOrder(Base):
    __tablename__ = "change_orders"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    delta_budget = Column(Numeric(12, 2), nullable=False, default=0)
    delta_scope = Column(JSONB, nullable=False, default=dict)
    status = Column(SQLEnum(ChangeOrderStatusEnum), nullable=False, default=ChangeOrderStatusEnum.DRAFT)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    organization = relationship("Organization")
    project = relationship("Project")
    approver = relationship("User")