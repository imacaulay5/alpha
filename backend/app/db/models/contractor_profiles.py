from sqlalchemy import Column, String, ForeignKey, Boolean, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db.base import Base

class ContractorProfile(Base):
    __tablename__ = "contractor_profiles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    default_rate = Column(Numeric(12, 2), nullable=False, default=0)
    role_title = Column(String(100), nullable=True)
    external_ref = Column(String(100), nullable=True)
    active = Column(Boolean, nullable=False, default=True)
    
    organization = relationship("Organization")
    user = relationship("User", back_populates="contractor_profile")