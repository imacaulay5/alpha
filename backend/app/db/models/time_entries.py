from sqlalchemy import Column, String, ForeignKey, Integer, DateTime, Text, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class StatusEnum(str, enum.Enum):
    DRAFT = "DRAFT"
    SUBMITTED = "SUBMITTED"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"

class SourceEnum(str, enum.Enum):
    MOBILE = "MOBILE"
    WEB = "WEB"
    IMPORT = "IMPORT"
    API = "API"

class TimeEntry(Base):
    __tablename__ = "time_entries"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    task_id = Column(UUID(as_uuid=True), ForeignKey("tasks.id"), nullable=False, index=True)
    start_at = Column(DateTime(timezone=True), nullable=False)
    end_at = Column(DateTime(timezone=True), nullable=True)
    duration_minutes = Column(Integer, nullable=False)
    notes = Column(Text, nullable=True)
    status = Column(SQLEnum(StatusEnum), nullable=False, default=StatusEnum.DRAFT)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)
    geo = Column(JSONB, nullable=True)
    source = Column(SQLEnum(SourceEnum), nullable=False, default=SourceEnum.WEB)
    
    organization = relationship("Organization")
    user = relationship("User", foreign_keys=[user_id])
    project = relationship("Project")
    task = relationship("Task", back_populates="time_entries")
    approver = relationship("User", foreign_keys=[approved_by])