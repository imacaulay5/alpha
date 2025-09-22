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
from app.db.models.contractor_profiles import ContractorProfile
from app.db.models.clients import Client
from app.db.models.projects import Project


class InvoiceService:
    """Service for creating and managing invoices."""

    def __init__(self):
        # Default rates and tax settings
        self.default_hourly_rate = Decimal('100.00')
        self.default_tax_rate = Decimal('0.00')  # 0% tax by default

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

    def get_effective_rate(
        self,
        task_id: UUID,
        user_id: UUID,
        db: Session
    ) -> Decimal:
        """
        Calculate the effective billing rate for a task/user combination.
        Priority: Task rate > User contractor rate > Default rate
        """
        try:
            # First, try to get task rate
            task = db.query(Task).filter(Task.id == task_id).first()
            if task and task.default_rate and float(task.default_rate) > 0:
                return Decimal(str(task.default_rate))

            # Second, try to get user contractor profile rate
            contractor_profile = db.query(ContractorProfile).filter(
                ContractorProfile.user_id == user_id,
                ContractorProfile.active == True
            ).first()
            if contractor_profile and contractor_profile.default_rate and float(contractor_profile.default_rate) > 0:
                return Decimal(str(contractor_profile.default_rate))

            # Fall back to default rate
            return self.default_hourly_rate

        except Exception as e:
            # Log error and return default rate
            print(f"Error calculating rate for task {task_id}, user {user_id}: {e}")
            return self.default_hourly_rate

    def calculate_tax_amount(
        self,
        subtotal: Decimal,
        client_id: UUID,
        db: Session
    ) -> Decimal:
        """
        Calculate tax amount based on client tax profile and subtotal.
        """
        try:
            # Get client tax profile
            client = db.query(Client).filter(Client.id == client_id).first()
            if not client:
                return Decimal('0.00')

            # Check if client has custom tax profile
            if client.default_tax_profile:
                tax_profile = client.default_tax_profile
                tax_rate = Decimal(str(tax_profile.get('rate', 0))) / Decimal('100')

                # Apply exemptions or special rules
                if tax_profile.get('exempt', False):
                    return Decimal('0.00')

                return subtotal * tax_rate

            # Use default tax rate (currently 0%)
            return subtotal * self.default_tax_rate

        except Exception as e:
            print(f"Error calculating tax for client {client_id}: {e}")
            return Decimal('0.00')

    def validate_invoice_creation_params(
        self,
        project_id: UUID,
        start_date: date,
        end_date: date,
        db: Session
    ) -> None:
        """
        Validate parameters for invoice creation.
        Raises ValueError if validation fails.
        """
        # Validate date range
        if start_date >= end_date:
            raise ValueError("Start date must be before end date")

        # Validate project exists
        project = db.query(Project).filter(Project.id == project_id).first()
        if not project:
            raise ValueError(f"Project with ID {project_id} not found")

        # Check if project is active (if status field exists)
        if hasattr(project, 'status') and project.status == 'INACTIVE':
            raise ValueError(f"Cannot create invoice for inactive project: {project.name}")

        # Validate date range is not too far in the future
        if start_date > datetime.now().date():
            raise ValueError("Cannot create invoice for future dates")

    def get_currency_for_project(
        self,
        project_id: UUID,
        db: Session
    ) -> str:
        """
        Get the appropriate currency for a project.
        Priority: Project currency > Client currency > Organization currency > USD
        """
        try:
            # Get project and related data
            project = db.query(Project).filter(Project.id == project_id).first()
            if not project:
                return "USD"

            # Check if project has currency (if field exists)
            if hasattr(project, 'currency') and project.currency:
                return project.currency

            # Check client default currency
            client = db.query(Client).filter(Client.id == project.client_id).first()
            if client and hasattr(client, 'currency') and client.currency:
                return client.currency

            # Check organization currency
            from app.db.models.organizations import Organization
            org = db.query(Organization).filter(Organization.id == project.org_id).first()
            if org and org.currency_code:
                return org.currency_code

            # Default to USD
            return "USD"

        except Exception as e:
            print(f"Error getting currency for project {project_id}: {e}")
            return "USD"

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

        # Calculate effective rate - handle mixed rates when grouping spans multiple tasks/users
        if len(set((entry.task_id, entry.user_id) for entry in entries)) == 1:
            # All entries have same task and user - use single rate
            first_entry = entries[0]
            effective_rate = self.get_effective_rate(
                task_id=first_entry.task_id,
                user_id=first_entry.user_id,
                db=db
            )
            amount = total_hours * effective_rate
        else:
            # Mixed tasks/users - calculate weighted amount based on individual rates
            amount = Decimal('0.00')
            effective_rate = Decimal('0.00')  # Will be calculated as weighted average

            for entry in entries:
                entry_hours = Decimal(entry.duration_minutes) / Decimal('60')
                entry_rate = self.get_effective_rate(
                    task_id=entry.task_id,
                    user_id=entry.user_id,
                    db=db
                )
                amount += entry_hours * entry_rate

            # Calculate weighted average rate for display
            if total_hours > 0:
                effective_rate = amount / total_hours

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
            unit_price=effective_rate,
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

        # Calculate tax using client tax profile
        tax_total = self.calculate_tax_amount(
            subtotal=subtotal,
            client_id=invoice.client_id,
            db=db
        )

        # Calculate total
        total = subtotal + tax_total

        # Update invoice
        invoice.subtotal = subtotal
        invoice.tax_total = tax_total
        invoice.total = total


# Global invoice service instance
invoice_service = InvoiceService()