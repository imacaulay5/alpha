"""
PDF Generation Service using ReportLab for better Windows compatibility.
"""

import io
from datetime import datetime
from typing import Dict, Any, Optional
from decimal import Decimal

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT
from sqlalchemy.orm import Session

from app.db.models.invoices import Invoice
from app.db.models.clients import Client
from app.db.models.projects import Project
from app.db.models.organizations import Organization


class ReportLabPDFService:
    """Service for generating PDF documents using ReportLab."""

    def __init__(self):
        self.styles = getSampleStyleSheet()
        self._setup_custom_styles()

    def _setup_custom_styles(self):
        """Set up custom paragraph styles."""
        self.styles.add(ParagraphStyle(
            name='InvoiceTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            spaceAfter=20,
            alignment=TA_CENTER
        ))

        self.styles.add(ParagraphStyle(
            name='CompanyName',
            parent=self.styles['Heading2'],
            fontSize=18,
            textColor=colors.HexColor('#4f46e5'),
            spaceAfter=6
        ))

        self.styles.add(ParagraphStyle(
            name='SectionHeader',
            parent=self.styles['Heading3'],
            fontSize=12,
            textColor=colors.HexColor('#4f46e5'),
            spaceAfter=6,
            spaceBefore=12
        ))

        self.styles.add(ParagraphStyle(
            name='RightAlign',
            parent=self.styles['Normal'],
            alignment=TA_RIGHT
        ))

    def generate_invoice_pdf(
        self,
        invoice: Invoice,
        db: Session,
        return_bytes: bool = True
    ) -> bytes:
        """
        Generate a PDF for the given invoice using ReportLab.

        Args:
            invoice: The invoice object to generate PDF for
            db: Database session for related data queries
            return_bytes: If True, return PDF as bytes

        Returns:
            PDF content as bytes
        """

        # Fetch related data
        client = db.query(Client).filter(Client.id == invoice.client_id).first()
        project = db.query(Project).filter(Project.id == invoice.project_id).first()
        organization = db.query(Organization).filter(
            Organization.id == invoice.org_id
        ).first()

        if not client or not project or not organization:
            raise ValueError("Missing related data for invoice PDF generation")

        # Create PDF buffer
        buffer = io.BytesIO()

        # Create document
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=inch,
            leftMargin=inch,
            topMargin=inch,
            bottomMargin=inch
        )

        # Build content
        story = []

        # Header section
        story.extend(self._build_header(organization, invoice))
        story.append(Spacer(1, 20))

        # Billing information
        story.extend(self._build_billing_section(client, project, invoice))
        story.append(Spacer(1, 20))

        # Invoice details table
        story.extend(self._build_invoice_table(invoice))
        story.append(Spacer(1, 20))

        # Totals section
        story.extend(self._build_totals_section(invoice))
        story.append(Spacer(1, 20))

        # Footer
        story.extend(self._build_footer(client))

        # Build PDF
        doc.build(story)

        # Get PDF bytes
        pdf_bytes = buffer.getvalue()
        buffer.close()

        return pdf_bytes

    def _build_header(self, organization: Organization, invoice: Invoice) -> list:
        """Build the header section."""
        content = []

        # Create header table with company info and invoice details
        header_data = [
            [
                Paragraph(f"<b>{organization.name}</b>", self.styles['CompanyName']),
                Paragraph(f"<b>Invoice {invoice.number}</b>", self.styles['InvoiceTitle'])
            ]
        ]

        # Add company details
        company_details = []
        if organization.address:
            company_details.append(organization.address)
        if organization.phone:
            company_details.append(f"Phone: {organization.phone}")
        if organization.email:
            company_details.append(f"Email: {organization.email}")

        if company_details:
            header_data.append([
                Paragraph("<br/>".join(company_details), self.styles['Normal']),
                Paragraph(f"Status: <b>{invoice.status}</b>", self.styles['RightAlign'])
            ])

        header_table = Table(header_data, colWidths=[3*inch, 3*inch])
        header_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (0, -1), 'LEFT'),
            ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
        ]))

        content.append(header_table)

        # Add line separator
        line_data = [['', '']]
        line_table = Table(line_data, colWidths=[6*inch])
        line_table.setStyle(TableStyle([
            ('LINEBELOW', (0, 0), (-1, 0), 2, colors.HexColor('#4f46e5')),
        ]))
        content.append(line_table)

        return content

    def _build_billing_section(self, client: Client, project: Project, invoice: Invoice) -> list:
        """Build the billing information section."""
        content = []

        # Bill To and Invoice Details
        billing_data = [
            [
                Paragraph("<b>Bill To:</b>", self.styles['SectionHeader']),
                Paragraph("<b>Invoice Details:</b>", self.styles['SectionHeader'])
            ]
        ]

        # Client details
        client_details = [client.name]
        if client.billing_contact_email:
            client_details.append(client.billing_contact_email)
        if client.address:
            client_details.append(client.address)

        # Invoice details
        invoice_details = [
            f"Issue Date: {invoice.issue_date.strftime('%B %d, %Y')}",
            f"Due Date: {invoice.due_date.strftime('%B %d, %Y')}",
            f"Project: {project.name} ({project.code})"
        ]
        if invoice.external_ref:
            invoice_details.append(f"Reference: {invoice.external_ref}")

        billing_data.append([
            Paragraph("<br/>".join(client_details), self.styles['Normal']),
            Paragraph("<br/>".join(invoice_details), self.styles['Normal'])
        ])

        billing_table = Table(billing_data, colWidths=[3*inch, 3*inch])
        billing_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ]))

        content.append(billing_table)
        return content

    def _build_invoice_table(self, invoice: Invoice) -> list:
        """Build the invoice line items table."""
        content = []

        # Table headers
        headers = ['Description', 'Quantity', 'Rate', 'Amount']
        table_data = [headers]

        # Add invoice lines
        for line in invoice.lines:
            description = line.description
            if line.meta and line.meta.get('date_range'):
                description += f"\n{line.meta['date_range']}"

            table_data.append([
                description,
                f"{float(line.quantity):.2f}",
                f"${float(line.unit_price):.2f}",
                f"${float(line.amount):.2f}"
            ])

        # Create table
        col_widths = [3*inch, 1*inch, 1*inch, 1*inch]
        line_table = Table(table_data, colWidths=col_widths)

        # Style the table
        line_table.setStyle(TableStyle([
            # Header row
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#f8fafc')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#374151')),
            ('ALIGN', (0, 0), (-1, 0), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),

            # Data rows
            ('ALIGN', (1, 1), (-1, -1), 'RIGHT'),  # Align numbers right
            ('ALIGN', (0, 1), (0, -1), 'LEFT'),    # Align description left
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f9f9f9')]),

            # Grid
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#e5e7eb')),
            ('LINEBELOW', (0, 0), (-1, 0), 2, colors.HexColor('#e2e8f0')),
        ]))

        content.append(line_table)
        return content

    def _build_totals_section(self, invoice: Invoice) -> list:
        """Build the totals section."""
        content = []

        # Create totals table (right-aligned)
        totals_data = [
            ['Subtotal:', f"${float(invoice.subtotal):.2f}"]
        ]

        if float(invoice.tax_total) > 0:
            totals_data.append(['Tax:', f"${float(invoice.tax_total):.2f}"])

        totals_data.append(['<b>Total:</b>', f"<b>${float(invoice.total):.2f}</b>"])

        # Create spacer and totals table
        spacer_table = Table([['', '']], colWidths=[4*inch, 2*inch])
        spacer_table.setStyle(TableStyle([('ALIGN', (0, 0), (-1, -1), 'RIGHT')]))

        totals_table = Table(totals_data, colWidths=[1*inch, 1*inch])
        totals_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, -2), 'Helvetica'),
            ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('LINEABOVE', (0, -1), (-1, -1), 1, colors.black),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
        ]))

        # Combine spacer and totals
        main_table = Table([[spacer_table, totals_table]], colWidths=[4*inch, 2*inch])
        content.append(main_table)

        return content

    def _build_footer(self, client: Client) -> list:
        """Build the footer section."""
        content = []

        content.append(Spacer(1, 30))

        # Payment terms
        terms_text = "Payment Terms: "
        if client.terms:
            terms_text += client.terms
        else:
            terms_text += "Payment is due within 30 days of invoice date."

        content.append(Paragraph(terms_text, self.styles['Normal']))
        content.append(Spacer(1, 20))

        # Footer
        footer_text = f"Generated on {datetime.now().strftime('%B %d, %Y at %I:%M %p')}<br/>Thank you for your business!"
        content.append(Paragraph(footer_text, self.styles['Normal']))

        return content


# Global PDF service instance
pdf_service = ReportLabPDFService()