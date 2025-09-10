from sqlalchemy import Column, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
import uuid
from app.db.base import Base

class SubcontractorAgreement(Base):
    __tablename__ = "subcontractor_agreements"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    subcontractor_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    rate = Column(Numeric(12, 2), nullable=False)
    markup = Column(Numeric(5, 2), nullable=False, default=0)
    terms = Column(JSONB, nullable=False, default=dict)
    
    organization = relationship("Organization")
    subcontractor = relationship("User", foreign_keys=[subcontractor_user_id])
    project = relationship("Project")