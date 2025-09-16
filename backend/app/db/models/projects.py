from sqlalchemy import Column, String, DateTime, ForeignKey, Date, Text, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class BillingModelEnum(str, enum.Enum):
    HOURLY = "HOURLY"
    FIXED = "FIXED"
    MILESTONE = "MILESTONE"
    RETAINER = "RETAINER"
    T_AND_M = "T&M"
    MIXED = "MIXED"

class Project(Base):
    __tablename__ = "projects"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    client_id = Column(UUID(as_uuid=True), ForeignKey("clients.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    code = Column(String(50), nullable=False)
    status = Column(String(50), nullable=False, default="ACTIVE")
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    billing_model = Column(SQLEnum(BillingModelEnum), nullable=False, default=BillingModelEnum.HOURLY)
    billing_settings = Column(JSONB, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    organization = relationship("Organization", back_populates="projects")
    client = relationship("Client", back_populates="projects")
    tasks = relationship("Task", back_populates="project")
    team_memberships = relationship("TeamMembership", back_populates="project")