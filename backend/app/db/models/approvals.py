from sqlalchemy import Column, String, ForeignKey, DateTime, Text, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class ItemTypeEnum(str, enum.Enum):
    TIME = "TIME"
    EXPENSE = "EXPENSE"
    CHANGE_ORDER = "CHANGE_ORDER"
    INVOICE = "INVOICE"

class DecisionEnum(str, enum.Enum):
    APPROVE = "APPROVE"
    REJECT = "REJECT"

class Approval(Base):
    __tablename__ = "approvals"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    item_type = Column(SQLEnum(ItemTypeEnum), nullable=False)
    item_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    approver_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    decision = Column(SQLEnum(DecisionEnum), nullable=False)
    comment = Column(Text, nullable=True)
    decided_at = Column(DateTime(timezone=True), server_default=func.now())
    
    organization = relationship("Organization")
    approver = relationship("User")