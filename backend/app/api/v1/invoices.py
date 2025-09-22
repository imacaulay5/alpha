from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.db.session import get_db
from app.db.models.invoices import Invoice, InvoiceLine, InvoiceStatusEnum, InvoiceLineKindEnum
from app.db.models.projects import Project
from app.db.models.clients import Client
from app.db.models.users import User
from app.core.deps import get_current_active_user, require_manager
from app.services.pdf_service import pdf_service
from app.services.invoice_service import invoice_service
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from uuid import UUID
import uuid
import io

router = APIRouter()

class InvoiceLineResponse(BaseModel):
    id: UUID
    kind: InvoiceLineKindEnum
    description: str
    quantity: float
    unit_price: float
    amount: float
    meta: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True

class InvoiceResponse(BaseModel):
    id: UUID
    org_id: UUID
    client_id: UUID
    project_id: UUID
    number: str
    issue_date: date
    due_date: date
    status: InvoiceStatusEnum
    subtotal: float
    tax_total: float
    total: float
    currency: str
    external_ref: Optional[str] = None

    # Related data for better UX
    client_name: Optional[str] = None
    project_name: Optional[str] = None
    lines: List[InvoiceLineResponse] = []

    class Config:
        from_attributes = True

class InvoiceCreateRequest(BaseModel):
    project_id: UUID
    range: Dict[str, str]  # {"from": "2024-01-01", "to": "2024-01-31"}
    include: Dict[str, bool]  # {"time": true, "expenses": true, "fixed": true}
    grouping: str = "TASK"

@router.get("/", response_model=List[InvoiceResponse])
async def list_invoices(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    client_id: Optional[UUID] = Query(None),
    status: Optional[InvoiceStatusEnum] = Query(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    List invoices for the current organization.
    """
    query = db.query(Invoice).filter(Invoice.org_id == current_user.org_id)

    # Apply filters
    if client_id:
        query = query.filter(Invoice.client_id == client_id)
    if status:
        query = query.filter(Invoice.status == status)

    invoices = query.offset(skip).limit(limit).all()

    # Build response with related data
    result = []
    for invoice in invoices:
        # Get related data
        client = db.query(Client).filter(Client.id == invoice.client_id).first()
        project = db.query(Project).filter(Project.id == invoice.project_id).first()

        # Build lines
        lines = []
        for line in invoice.lines:
            lines.append(InvoiceLineResponse(
                id=line.id,
                kind=line.kind,
                description=line.description,
                quantity=float(line.quantity),
                unit_price=float(line.unit_price),
                amount=float(line.amount),
                meta=line.meta
            ))

        result.append(InvoiceResponse(
            id=invoice.id,
            org_id=invoice.org_id,
            client_id=invoice.client_id,
            project_id=invoice.project_id,
            number=invoice.number,
            issue_date=invoice.issue_date,
            due_date=invoice.due_date,
            status=invoice.status,
            subtotal=float(invoice.subtotal),
            tax_total=float(invoice.tax_total),
            total=float(invoice.total),
            currency=invoice.currency,
            external_ref=invoice.external_ref,
            client_name=client.name if client else None,
            project_name=project.name if project else None,
            lines=lines
        ))

    return result

@router.post("/", response_model=InvoiceResponse)
async def create_invoice(
    invoice_data: InvoiceCreateRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Create a new invoice from time entries and expenses.
    """
    # Verify project exists and user has access
    project = db.query(Project).filter(
        Project.id == invoice_data.project_id,
        Project.org_id == current_user.org_id
    ).first()
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    # Parse date range
    try:
        start_date = datetime.strptime(invoice_data.range["from"], "%Y-%m-%d").date()
        end_date = datetime.strptime(invoice_data.range["to"], "%Y-%m-%d").date()
    except (KeyError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date range format. Use YYYY-MM-DD."
        )

    # Generate invoice number
    invoice_count = db.query(Invoice).filter(Invoice.org_id == current_user.org_id).count()
    invoice_number = f"INV-{(invoice_count + 1):04d}"

    # Calculate due date (30 days from issue date by default)
    issue_date = datetime.now().date()
    due_date = issue_date + timedelta(days=30)

    # Create invoice
    invoice = Invoice(
        id=uuid.uuid4(),
        org_id=current_user.org_id,
        client_id=project.client_id,
        project_id=project.id,
        number=invoice_number,
        issue_date=issue_date,
        due_date=due_date,
        status=InvoiceStatusEnum.DRAFT,
        subtotal=0,
        tax_total=0,
        total=0,
        currency="USD"
    )

    db.add(invoice)
    db.flush()

    # Generate invoice lines from time entries and expenses
    all_lines = []

    # Add time entry lines if requested
    if invoice_data.include.get("time", False):
        time_lines = invoice_service.create_invoice_lines_from_time_entries(
            invoice=invoice,
            project_id=invoice_data.project_id,
            start_date=start_date,
            end_date=end_date,
            grouping=invoice_data.grouping,
            db=db
        )
        all_lines.extend(time_lines)

    # Add expense lines if requested
    if invoice_data.include.get("expenses", False):
        expense_lines = invoice_service.create_invoice_lines_from_expenses(
            invoice=invoice,
            project_id=invoice_data.project_id,
            start_date=start_date,
            end_date=end_date,
            db=db
        )
        all_lines.extend(expense_lines)

    # If no lines were created, add a placeholder
    if not all_lines:
        line = InvoiceLine(
            id=uuid.uuid4(),
            invoice_id=invoice.id,
            kind=InvoiceLineKindEnum.TIME,
            description=f"Services for {project.name} ({start_date} to {end_date})",
            quantity=1,
            unit_price=0,
            amount=0,
            meta={"note": "No billable time entries or expenses found for this period"}
        )
        all_lines.append(line)

    # Add all lines to database
    for line in all_lines:
        db.add(line)

    # Calculate invoice totals
    invoice_service.calculate_invoice_totals(invoice, db)

    db.commit()
    db.refresh(invoice)

    return await get_invoice(invoice.id, current_user, db)

@router.get("/{invoice_id}", response_model=InvoiceResponse)
async def get_invoice(
    invoice_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific invoice by ID.
    """
    invoice = db.query(Invoice).filter(
        Invoice.id == invoice_id,
        Invoice.org_id == current_user.org_id
    ).first()

    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )

    # Get related data
    client = db.query(Client).filter(Client.id == invoice.client_id).first()
    project = db.query(Project).filter(Project.id == invoice.project_id).first()

    # Build lines
    lines = []
    for line in invoice.lines:
        lines.append(InvoiceLineResponse(
            id=line.id,
            kind=line.kind,
            description=line.description,
            quantity=float(line.quantity),
            unit_price=float(line.unit_price),
            amount=float(line.amount),
            meta=line.meta
        ))

    return InvoiceResponse(
        id=invoice.id,
        org_id=invoice.org_id,
        client_id=invoice.client_id,
        project_id=invoice.project_id,
        number=invoice.number,
        issue_date=invoice.issue_date,
        due_date=invoice.due_date,
        status=invoice.status,
        subtotal=float(invoice.subtotal),
        tax_total=float(invoice.tax_total),
        total=float(invoice.total),
        currency=invoice.currency,
        external_ref=invoice.external_ref,
        client_name=client.name if client else None,
        project_name=project.name if project else None,
        lines=lines
    )

@router.patch("/{invoice_id}", response_model=InvoiceResponse)
async def update_invoice(
    invoice_id: UUID,
    updates: Dict[str, Any],
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Update an invoice.
    """
    invoice = db.query(Invoice).filter(
        Invoice.id == invoice_id,
        Invoice.org_id == current_user.org_id
    ).first()

    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )

    # Only allow updates to draft invoices
    if invoice.status != InvoiceStatusEnum.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only draft invoices can be modified"
        )

    # Update fields
    for field, value in updates.items():
        if hasattr(invoice, field):
            setattr(invoice, field, value)

    db.commit()
    db.refresh(invoice)

    return await get_invoice(invoice.id, current_user, db)

@router.delete("/{invoice_id}")
async def delete_invoice(
    invoice_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Delete an invoice. Only draft invoices can be deleted.
    """
    invoice = db.query(Invoice).filter(
        Invoice.id == invoice_id,
        Invoice.org_id == current_user.org_id
    ).first()

    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )

    if invoice.status != InvoiceStatusEnum.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only draft invoices can be deleted"
        )

    db.delete(invoice)
    db.commit()

    return {"message": "Invoice deleted successfully"}

@router.post("/{invoice_id}/pdf")
async def generate_invoice_pdf(
    invoice_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Generate and download a PDF for the specified invoice.
    """
    # Get the invoice
    invoice = db.query(Invoice).filter(
        Invoice.id == invoice_id,
        Invoice.org_id == current_user.org_id
    ).first()

    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )

    try:
        # Generate PDF
        pdf_bytes = pdf_service.generate_invoice_pdf(invoice, db)

        # Create a streaming response
        pdf_stream = io.BytesIO(pdf_bytes)

        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename=invoice_{invoice.number}.pdf"
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate PDF: {str(e)}"
        )
