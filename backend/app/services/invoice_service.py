"""
Invoice Service for creating invoice lines from time entries and expenses.
Handles aggregation and billing rules application.
"""

from datetime import datetime, date, timedelta
from decimal import Decimal
from typing import List, Dict, Any, Optional
from uuid import UUID
import uuid

from sqlalchemy.orm import Session
from sqlalchemy import and_, func

from app.db.models.invoices import Invoice, InvoiceLine, InvoiceLineKindEnum
from app.db.models.time_entries import TimeEntry
from app.db.models.expenses import Expense
from app.db.models.tasks import Task
from app.db.models.users import User


class InvoiceService:
    """Service for creating and managing invoices."""

    def __init__(self):
        pass

    def create_invoice_lines_from_time_entries(
        self,
        invoice: Invoice,
        project_id: UUID,
        start_date: date,
        end_date: date,
        grouping: str,
        db: Session
    ) -> List[InvoiceLine]:
        """
        Create invoice lines from time entries within the specified date range.

        Args:
            invoice: The invoice to create lines for
            project_id: Project ID to filter time entries
            start_date: Start date for time entry range
            end_date: End date for time entry range
            grouping: How to group the time entries (TASK, USER, WEEK, DAY)
            db: Database session

        Returns:
            List of created invoice lines
        """

        # Query time entries for the project within date range
        time_entries = db.query(TimeEntry).filter(
            and_(
                TimeEntry.project_id == project_id,
                func.date(TimeEntry.start_at) >= start_date,
                func.date(TimeEntry.start_at) <= end_date,
                TimeEntry.status == 'APPROVED'  # Only include approved entries
            )
        ).all()

        if not time_entries:
            return []

        # Group time entries based on grouping strategy
        grouped_entries = self._group_time_entries(time_entries, grouping, db)

        # Create invoice lines
        invoice_lines = []
        for group_key, entries in grouped_entries.items():
            line = self._create_time_entry_line(
                invoice, group_key, entries, grouping, db
            )
            if line:
                invoice_lines.append(line)

        return invoice_lines

    def create_invoice_lines_from_expenses(
        self,
        invoice: Invoice,
        project_id: UUID,
        start_date: date,
        end_date: date,
        db: Session
    ) -> List[InvoiceLine]:
        """
        Create invoice lines from expenses within the specified date range.

        Args:
            invoice: The invoice to create lines for
            project_id: Project ID to filter expenses
            start_date: Start date for expense range
            end_date: End date for expense range
            db: Database session

        Returns:
            List of created invoice lines
        """

        # Query expenses for the project within date range
        expenses = db.query(Expense).filter(
            and_(
                Expense.project_id == project_id,
                func.date(Expense.created_at) >= start_date,
                func.date(Expense.created_at) <= end_date,
                Expense.status == 'APPROVED'  # Only include approved expenses
            )
        ).all()

        if not expenses:
            return []

        # Group expenses by category or create individual lines
        expense_lines = []
        for expense in expenses:
            line = InvoiceLine(
                id=uuid.uuid4(),
                invoice_id=invoice.id,
                kind=InvoiceLineKindEnum.EXPENSE,
                description=expense.notes or f"Expense - {expense.amount} {expense.currency}",
                quantity=Decimal('1.00'),
                unit_price=Decimal(str(expense.amount)),
                amount=Decimal(str(expense.amount)),
                meta={
                    'expense_id': str(expense.id),
                    'date': expense.created_at.strftime('%Y-%m-%d'),
                    'currency': expense.currency
                }
            )
            expense_lines.append(line)

        return expense_lines

    def _group_time_entries(
        self,
        time_entries: List[TimeEntry],
        grouping: str,
        db: Session
    ) -> Dict[str, List[TimeEntry]]:
        """Group time entries based on the specified grouping strategy."""

        grouped = {}

        for entry in time_entries:
            if grouping == "TASK":
                # Get task name for grouping
                task = db.query(Task).filter(Task.id == entry.task_id).first()
                key = f"task_{entry.task_id}_{task.name if task else 'Unknown Task'}"
            elif grouping == "USER":
                # Get user name for grouping
                user = db.query(User).filter(User.id == entry.user_id).first()
                key = f"user_{entry.user_id}_{user.name if user else 'Unknown User'}"
            elif grouping == "WEEK":
                # Group by week
                week_start = entry.start_at.date() - timedelta(
                    days=entry.start_at.weekday()
                )
                key = f"week_{week_start.strftime('%Y-%m-%d')}"
            elif grouping == "DAY":
                # Group by day
                key = f"day_{entry.start_at.date().strftime('%Y-%m-%d')}"
            else:
                # Default to task grouping
                task = db.query(Task).filter(Task.id == entry.task_id).first()
                key = f"task_{entry.task_id}_{task.name if task else 'Unknown Task'}"

            if key not in grouped:
                grouped[key] = []
            grouped[key].append(entry)

        return grouped

    def _create_time_entry_line(
        self,
        invoice: Invoice,
        group_key: str,
        entries: List[TimeEntry],
        grouping: str,
        db: Session
    ) -> Optional[InvoiceLine]:
        """Create a single invoice line from grouped time entries."""

        if not entries:
            return None

        # Calculate totals
        total_duration = sum(entry.duration_minutes for entry in entries)
        total_hours = Decimal(total_duration) / Decimal('60')

        # Get rate - for now, use a default rate
        # TODO: Apply billing rules to determine the correct rate
        default_rate = Decimal('100.00')  # $100/hour default

        # Calculate amount
        amount = total_hours * default_rate

        # Create description based on grouping
        if grouping == "TASK":
            # Extract task name from group key
            task_name = group_key.split('_', 2)[2] if '_' in group_key else 'Task'
            description = f"{task_name} - {total_hours:.2f} hours"
        elif grouping == "USER":
            user_name = group_key.split('_', 2)[2] if '_' in group_key else 'User'
            description = f"{user_name} - {total_hours:.2f} hours"
        elif grouping == "WEEK":
            week_date = group_key.split('_')[1]
            description = f"Week of {week_date} - {total_hours:.2f} hours"
        elif grouping == "DAY":
            day_date = group_key.split('_')[1]
            description = f"{day_date} - {total_hours:.2f} hours"
        else:
            description = f"Time entries - {total_hours:.2f} hours"

        # Create meta data with entry details
        entry_details = []
        for entry in entries:
            entry_details.append({
                'id': str(entry.id),
                'date': entry.start_at.strftime('%Y-%m-%d'),
                'duration_minutes': entry.duration_minutes,
                'notes': entry.notes
            })

        meta = {
            'grouping': grouping,
            'total_duration_minutes': total_duration,
            'entry_count': len(entries),
            'entries': entry_details,
            'date_range': f"{min(e.start_at.date() for e in entries)} to {max(e.start_at.date() for e in entries)}"
        }

        # Create the invoice line
        line = InvoiceLine(
            id=uuid.uuid4(),
            invoice_id=invoice.id,
            kind=InvoiceLineKindEnum.TIME,
            description=description,
            quantity=total_hours,
            unit_price=default_rate,
            amount=amount,
            meta=meta
        )

        return line

    def calculate_invoice_totals(self, invoice: Invoice, db: Session) -> None:
        """Calculate and update invoice totals based on lines."""

        # Get all lines for this invoice
        lines = db.query(InvoiceLine).filter(
            InvoiceLine.invoice_id == invoice.id
        ).all()

        # Calculate subtotal
        subtotal = sum(Decimal(str(line.amount)) for line in lines)

        # Calculate tax (TODO: implement proper tax calculation)
        tax_rate = Decimal('0.00')  # No tax for now
        tax_total = subtotal * tax_rate

        # Calculate total
        total = subtotal + tax_total

        # Update invoice
        invoice.subtotal = subtotal
        invoice.tax_total = tax_total
        invoice.total = total


# Global invoice service instance
invoice_service = InvoiceService()