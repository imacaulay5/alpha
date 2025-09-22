"""
PDF Generation Service for invoices and other documents.
Uses ReportLab for cross-platform PDF generation.
"""

# Import the ReportLab-based service
from .pdf_service_reportlab import ReportLabPDFService

# Use ReportLab service as the main PDF service
pdf_service = ReportLabPDFService()