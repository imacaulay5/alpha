//
//  InvoicePDFGenerator.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import UIKit
import PDFKit

class InvoicePDFGenerator {

    // MARK: - Configuration

    private struct Layout {
        static let pageWidth: CGFloat = 612 // US Letter width in points
        static let pageHeight: CGFloat = 792 // US Letter height in points
        static let margin: CGFloat = 50
        static let contentWidth: CGFloat = pageWidth - (margin * 2)
    }

    private struct Colors {
        static let primary = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        static let secondary = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        static let lightGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        static let text = UIColor.black
        static let subtleText = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    }

    private struct Fonts {
        static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let heading = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 11, weight: .regular)
        static let bodyBold = UIFont.systemFont(ofSize: 11, weight: .semibold)
        static let small = UIFont.systemFont(ofSize: 9, weight: .regular)
        static let large = UIFont.systemFont(ofSize: 16, weight: .bold)
    }

    // MARK: - Public Methods

    func generatePDF(for invoice: Invoice, organization: Organization?) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = Layout.margin

            // Header with organization info and invoice title
            yPosition = drawHeader(invoice: invoice, organization: organization, yPosition: yPosition)

            // Invoice details (number, dates, status)
            yPosition = drawInvoiceDetails(invoice: invoice, yPosition: yPosition)

            // Bill To section
            yPosition = drawBillTo(invoice: invoice, yPosition: yPosition)

            // Line items table
            yPosition = drawLineItems(invoice: invoice, yPosition: yPosition)

            // Totals
            yPosition = drawTotals(invoice: invoice, yPosition: yPosition)

            // Notes
            if let notes = invoice.notes, !notes.isEmpty {
                yPosition = drawNotes(notes: notes, yPosition: yPosition)
            }

            // Footer
            drawFooter(organization: organization)
        }

        return data
    }

    func savePDF(_ data: Data, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfPath = documentsPath.appendingPathComponent("\(filename).pdf")

        do {
            try data.write(to: pdfPath)
            return pdfPath
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }

    // MARK: - Drawing Methods

    private func drawHeader(invoice: Invoice, organization: Organization?, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        // Organization name (left side)
        let orgName = organization?.name ?? "Your Company"
        let orgAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.primary
        ]
        let orgRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth * 0.6, height: 35)
        orgName.draw(in: orgRect, withAttributes: orgAttributes)

        // INVOICE label (right side)
        let invoiceLabel = "INVOICE"
        let invoiceLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.secondary
        ]
        let labelSize = invoiceLabel.size(withAttributes: invoiceLabelAttributes)
        let labelX = Layout.pageWidth - Layout.margin - labelSize.width
        invoiceLabel.draw(at: CGPoint(x: labelX, y: y), withAttributes: invoiceLabelAttributes)

        y += 40

        // Organization contact info
        if let org = organization {
            let contactInfo = [
                org.address,
                [org.city, org.state, org.zipCode].compactMap { $0 }.joined(separator: ", "),
                org.email,
                org.phone
            ].compactMap { $0 }.filter { !$0.isEmpty }

            let contactAttributes: [NSAttributedString.Key: Any] = [
                .font: Fonts.body,
                .foregroundColor: Colors.subtleText
            ]

            for line in contactInfo {
                line.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: contactAttributes)
                y += 14
            }
        }

        y += 20
        return y
    }

    private func drawInvoiceDetails(invoice: Invoice, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        // Draw a light background box
        let boxRect = CGRect(x: Layout.pageWidth - Layout.margin - 200, y: y, width: 200, height: 80)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 4)
        Colors.lightGray.setFill()
        boxPath.fill()

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.small,
            .foregroundColor: Colors.subtleText
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.bodyBold,
            .foregroundColor: Colors.text
        ]

        let detailsX = Layout.pageWidth - Layout.margin - 190
        var detailsY = y + 10

        // Invoice Number
        "Invoice Number".draw(at: CGPoint(x: detailsX, y: detailsY), withAttributes: labelAttributes)
        detailsY += 12
        invoice.invoiceNumber.draw(at: CGPoint(x: detailsX, y: detailsY), withAttributes: valueAttributes)
        detailsY += 18

        // Issue Date
        "Issue Date".draw(at: CGPoint(x: detailsX, y: detailsY), withAttributes: labelAttributes)
        detailsY += 12
        formatDate(invoice.issueDate).draw(at: CGPoint(x: detailsX, y: detailsY), withAttributes: valueAttributes)

        // Due Date (right column)
        let rightColX = detailsX + 100
        detailsY = y + 10 + 12 + 18

        "Due Date".draw(at: CGPoint(x: rightColX, y: detailsY), withAttributes: labelAttributes)
        detailsY += 12
        formatDate(invoice.dueDate).draw(at: CGPoint(x: rightColX, y: detailsY), withAttributes: valueAttributes)

        return y + 100
    }

    private func drawBillTo(invoice: Invoice, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.primary
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]

        "BILL TO".draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: headerAttributes)
        y += 20

        if let client = invoice.client {
            client.name.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: [
                .font: Fonts.bodyBold,
                .foregroundColor: Colors.text
            ])
            y += 16

            let clientInfo = [
                client.contactName,
                client.address,
                [client.city, client.state, client.zipCode].compactMap { $0 }.joined(separator: ", "),
                client.email,
                client.phone
            ].compactMap { $0 }.filter { !$0.isEmpty }

            for line in clientInfo {
                line.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: bodyAttributes)
                y += 14
            }
        }

        y += 20
        return y
    }

    private func drawLineItems(invoice: Invoice, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        // Table header
        let headerY = y
        let headerRect = CGRect(x: Layout.margin, y: headerY, width: Layout.contentWidth, height: 25)
        Colors.primary.setFill()
        UIBezierPath(rect: headerRect).fill()

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.bodyBold,
            .foregroundColor: UIColor.white
        ]

        let columns: [(String, CGFloat, NSTextAlignment)] = [
            ("Description", Layout.margin + 10, .left),
            ("Qty", Layout.margin + 280, .center),
            ("Rate", Layout.margin + 340, .right),
            ("Amount", Layout.margin + 430, .right)
        ]

        for (title, x, _) in columns {
            title.draw(at: CGPoint(x: x, y: headerY + 6), withAttributes: headerAttributes)
        }

        y += 30

        // Line items
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]

        let lineItems = invoice.lineItems ?? []
        for (index, item) in lineItems.enumerated() {
            // Alternate row background
            if index % 2 == 1 {
                let rowRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: 22)
                Colors.lightGray.setFill()
                UIBezierPath(rect: rowRect).fill()
            }

            let rowY = y + 5

            // Description
            item.description.draw(at: CGPoint(x: Layout.margin + 10, y: rowY), withAttributes: rowAttributes)

            // Quantity
            let qtyText = formatQuantity(item.quantity)
            drawRightAligned(text: qtyText, x: Layout.margin + 310, y: rowY, attributes: rowAttributes)

            // Rate
            let rateText = formatCurrency(item.rate)
            drawRightAligned(text: rateText, x: Layout.margin + 390, y: rowY, attributes: rowAttributes)

            // Amount
            let amountText = formatCurrency(item.amount)
            drawRightAligned(text: amountText, x: Layout.margin + 500, y: rowY, attributes: rowAttributes)

            y += 22
        }

        y += 10
        return y
    }

    private func drawTotals(invoice: Invoice, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.subtleText
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]
        let totalLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.large,
            .foregroundColor: Colors.text
        ]
        let totalValueAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.large,
            .foregroundColor: Colors.primary
        ]

        let labelX: CGFloat = Layout.margin + 350
        let valueX: CGFloat = Layout.margin + 500

        // Subtotal
        "Subtotal".draw(at: CGPoint(x: labelX, y: y), withAttributes: labelAttributes)
        drawRightAligned(text: formatCurrency(invoice.subtotal), x: valueX, y: y, attributes: valueAttributes)
        y += 20

        // Tax
        if let taxRate = invoice.taxRate, let taxAmount = invoice.taxAmount, taxAmount > 0 {
            let taxLabel = "Tax (\(formatPercentage(taxRate)))"
            taxLabel.draw(at: CGPoint(x: labelX, y: y), withAttributes: labelAttributes)
            drawRightAligned(text: formatCurrency(taxAmount), x: valueX, y: y, attributes: valueAttributes)
            y += 20
        }

        // Divider line
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: labelX, y: y))
        dividerPath.addLine(to: CGPoint(x: valueX, y: y))
        Colors.secondary.setStroke()
        dividerPath.lineWidth = 1
        dividerPath.stroke()
        y += 10

        // Total
        "TOTAL".draw(at: CGPoint(x: labelX, y: y), withAttributes: totalLabelAttributes)
        drawRightAligned(text: formatCurrency(invoice.total), x: valueX, y: y, attributes: totalValueAttributes)

        y += 40
        return y
    }

    private func drawNotes(notes: String, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.primary
        ]
        let notesAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.subtleText
        ]

        "Notes".draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: headerAttributes)
        y += 18

        let notesRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: 60)
        notes.draw(in: notesRect, withAttributes: notesAttributes)

        y += 70
        return y
    }

    private func drawFooter(organization: Organization?) {
        let footerY = Layout.pageHeight - Layout.margin - 30

        let attributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.small,
            .foregroundColor: Colors.subtleText
        ]

        let thankYouText = "Thank you for your business!"
        let thankYouSize = thankYouText.size(withAttributes: attributes)
        let centerX = (Layout.pageWidth - thankYouSize.width) / 2
        thankYouText.draw(at: CGPoint(x: centerX, y: footerY), withAttributes: attributes)

        if let org = organization {
            let contactText = [org.email, org.phone].compactMap { $0 }.joined(separator: " | ")
            let contactSize = contactText.size(withAttributes: attributes)
            let contactX = (Layout.pageWidth - contactSize.width) / 2
            contactText.draw(at: CGPoint(x: contactX, y: footerY + 14), withAttributes: attributes)
        }
    }

    // MARK: - Helper Methods

    private func drawRightAligned(text: String, x: CGFloat, y: CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: x - size.width, y: y), withAttributes: attributes)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    private func formatQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    private func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value)
    }
}
