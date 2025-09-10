from sqlalchemy import Column, String, ForeignKey, Boolean, Numeric, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class UOMEnum(str, enum.Enum):
    HOUR = "HOUR"
    ITEM = "ITEM"
    DAY = "DAY"

class Task(Base):
    __tablename__ = "tasks"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False)
    is_billable = Column(Boolean, nullable=False, default=True)
    default_rate = Column(Numeric(12, 2), nullable=False, default=0)
    uom = Column(SQLEnum(UOMEnum), nullable=False, default=UOMEnum.HOUR)
    
    organization = relationship("Organization")
    project = relationship("Project", back_populates="tasks")
    time_entries = relationship("TimeEntry", back_populates="task")
    expenses = relationship("Expense", back_populates="task")