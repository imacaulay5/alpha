from sqlalchemy import Column, ForeignKey, Boolean, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class TeamRoleEnum(str, enum.Enum):
    LEAD = "LEAD"
    MEMBER = "MEMBER"
    SUB = "SUB"

class TeamMembership(Base):
    __tablename__ = "team_memberships"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    role = Column(SQLEnum(TeamRoleEnum), nullable=False, default=TeamRoleEnum.MEMBER)
    billable = Column(Boolean, nullable=False, default=True)
    visibility = Column(JSONB, nullable=False, default=dict)
    
    organization = relationship("Organization")
    project = relationship("Project", back_populates="team_memberships")
    user = relationship("User")