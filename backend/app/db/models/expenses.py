from sqlalchemy import Column, String, ForeignKey, Numeric, Text, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db.base import Base
from .time_entries import StatusEnum

class Expense(Base):
    __tablename__ = "expenses"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    task_id = Column(UUID(as_uuid=True), ForeignKey("tasks.id"), nullable=False, index=True)
    amount = Column(Numeric(12, 2), nullable=False)
    currency = Column(String(3), nullable=False, default="USD")
    receipt_url = Column(String(500), nullable=True)
    notes = Column(Text, nullable=True)
    status = Column(SQLEnum(StatusEnum), nullable=False, default=StatusEnum.DRAFT)
    
    organization = relationship("Organization")
    user = relationship("User")
    project = relationship("Project")
    task = relationship("Task", back_populates="expenses")