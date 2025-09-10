from sqlalchemy import Column, String, ForeignKey, Numeric, Date, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
import uuid
import enum
from app.db.base import Base

class InvoiceStatusEnum(str, enum.Enum):
    DRAFT = "DRAFT"
    SENT = "SENT"
    PAID = "PAID"
    VOID = "VOID"

class InvoiceLineKindEnum(str, enum.Enum):
    TIME = "TIME"
    EXPENSE = "EXPENSE"
    FIXED = "FIXED"
    MILESTONE = "MILESTONE"
    RETAINER = "RETAINER"
    ADJUSTMENT = "ADJUSTMENT"
    RETAINAGE = "RETAINAGE"

class Invoice(Base):
    __tablename__ = "invoices"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False, index=True)
    client_id = Column(UUID(as_uuid=True), ForeignKey("clients.id"), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    number = Column(String(50), nullable=False, unique=True)
    issue_date = Column(Date, nullable=False)
    due_date = Column(Date, nullable=False)
    status = Column(SQLEnum(InvoiceStatusEnum), nullable=False, default=InvoiceStatusEnum.DRAFT)
    subtotal = Column(Numeric(12, 2), nullable=False, default=0)
    tax_total = Column(Numeric(12, 2), nullable=False, default=0)
    total = Column(Numeric(12, 2), nullable=False, default=0)
    currency = Column(String(3), nullable=False, default="USD")
    external_ref = Column(String(100), nullable=True)
    
    organization = relationship("Organization")
    client = relationship("Client")
    project = relationship("Project")
    lines = relationship("InvoiceLine", back_populates="invoice")

class InvoiceLine(Base):
    __tablename__ = "invoice_lines"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    invoice_id = Column(UUID(as_uuid=True), ForeignKey("invoices.id"), nullable=False, index=True)
    kind = Column(SQLEnum(InvoiceLineKindEnum), nullable=False)
    description = Column(String(500), nullable=False)
    quantity = Column(Numeric(12, 2), nullable=False, default=1)
    unit_price = Column(Numeric(12, 2), nullable=False, default=0)
    amount = Column(Numeric(12, 2), nullable=False, default=0)
    meta = Column(JSONB, nullable=False, default=dict)
    
    invoice = relationship("Invoice", back_populates="lines")