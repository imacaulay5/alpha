from sqlalchemy import Column, String, ForeignKey, Integer, Boolean, DateTime, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class ScopeEnum(str, enum.Enum):
    ORG = "ORG"
    CLIENT = "CLIENT"
    PROJECT = "PROJECT"
    TASK = "TASK"
    USER = "USER"

class BillingRule(Base):
    __tablename__ = "billing_rules"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    scope = Column(SQLEnum(ScopeEnum), nullable=False)
    scope_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    priority = Column(Integer, nullable=False, default=100)
    rule = Column(JSONB, nullable=False)
    active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    organization = relationship("Organization")