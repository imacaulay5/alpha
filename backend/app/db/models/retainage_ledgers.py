from sqlalchemy import Column, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
import uuid
from app.db.base import Base

class RetainageLedger(Base):
    __tablename__ = "retainage_ledgers"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    retainage_rate = Column(Numeric(5, 2), nullable=False, default=0)
    retained_total = Column(Numeric(12, 2), nullable=False, default=0)
    released_total = Column(Numeric(12, 2), nullable=False, default=0)
    entries = Column(JSONB, nullable=False, default=list)
    
    organization = relationship("Organization")
    project = relationship("Project")