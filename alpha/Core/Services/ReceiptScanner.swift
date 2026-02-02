//
//  ReceiptScanner.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import UIKit
import Vision
import VisionKit

// MARK: - Scanned Receipt Data

struct ScannedReceiptData {
    var merchant: String?
    var amount: Double?
    var date: Date?
    var category: ExpenseCategory?
    var items: [String]
    var rawText: String

    init() {
        self.items = []
        self.rawText = ""
    }
}

// MARK: - Receipt Scanner Delegate

protocol ReceiptScannerDelegate: AnyObject {
    func receiptScanner(_ scanner: ReceiptScanner, didFinishWith result: ScannedReceiptData)
    func receiptScanner(_ scanner: ReceiptScanner, didFailWith error: Error)
    func receiptScannerDidCancel(_ scanner: ReceiptScanner)
}

// MARK: - Receipt Scanner

@MainActor
class ReceiptScanner: NSObject {

    weak var delegate: ReceiptScannerDelegate?

    private var scannerViewController: VNDocumentCameraViewController?

    // MARK: - Public Methods

    static var isAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    func presentScanner(from viewController: UIViewController) {
        guard Self.isAvailable else {
            let error = NSError(
                domain: "ReceiptScanner",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Document scanning is not available on this device"]
            )
            delegate?.receiptScanner(self, didFailWith: error)
            return
        }

        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        self.scannerViewController = scanner

        viewController.present(scanner, animated: true)
    }

    // MARK: - Text Recognition

    private func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(
                domain: "ReceiptScanner",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to process image"]
            )
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])

                    guard let observations = request.results else {
                        continuation.resume(returning: "")
                        return
                    }

                    let recognizedText = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")

                    continuation.resume(returning: recognizedText)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Receipt Parsing

    private func parseReceipt(from text: String) -> ScannedReceiptData {
        var data = ScannedReceiptData()
        data.rawText = text

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Extract merchant (usually first non-empty line or line with store name patterns)
        data.merchant = extractMerchant(from: lines)

        // Extract total amount
        data.amount = extractTotal(from: lines)

        // Extract date
        data.date = extractDate(from: text)

        // Guess category based on merchant/items
        data.category = guessCategory(merchant: data.merchant, text: text)

        // Extract line items
        data.items = extractItems(from: lines)

        return data
    }

    private func extractMerchant(from lines: [String]) -> String? {
        // Common store name patterns - check first few lines
        for line in lines.prefix(5) {
            let uppercased = line.uppercased()

            // Skip lines that look like addresses, dates, or receipt headers
            if line.contains("RECEIPT") || line.contains("INVOICE") {
                continue
            }
            if line.contains("/") && line.count < 15 { // Likely a date
                continue
            }
            if line.first?.isNumber == true && line.contains("-") { // Phone number
                continue
            }

            // Return the first substantial line that looks like a store name
            if line.count > 2 && line.count < 50 {
                // Check if it's mostly letters (store name) vs numbers (receipt number)
                let letterCount = line.filter { $0.isLetter || $0.isWhitespace }.count
                if Double(letterCount) / Double(line.count) > 0.5 {
                    return line
                }
            }
        }

        return lines.first
    }

    private func extractTotal(from lines: [String]) -> Double? {
        // Patterns for total amount
        let totalPatterns = [
            "TOTAL",
            "GRAND TOTAL",
            "AMOUNT DUE",
            "BALANCE DUE",
            "SUBTOTAL",
            "SUM",
            "CHARGE"
        ]

        // Look for lines containing total keywords
        for line in lines.reversed() { // Start from bottom - totals usually at end
            let uppercased = line.uppercased()

            for pattern in totalPatterns {
                if uppercased.contains(pattern) {
                    if let amount = extractAmount(from: line) {
                        return amount
                    }
                }
            }
        }

        // Fallback: find the largest dollar amount
        var amounts: [Double] = []
        for line in lines {
            if let amount = extractAmount(from: line) {
                amounts.append(amount)
            }
        }

        return amounts.max()
    }

    private func extractAmount(from text: String) -> Double? {
        // Match currency patterns: $12.34, 12.34, $1,234.56
        let patterns = [
            "\\$\\s*([0-9,]+\\.?[0-9]*)",  // $12.34 or $1,234.56
            "([0-9,]+\\.[0-9]{2})(?:\\s|$)", // 12.34 at end of line
            "USD\\s*([0-9,]+\\.?[0-9]*)"    // USD 12.34
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
                if let amount = Double(amountString), amount > 0 {
                    return amount
                }
            }
        }

        return nil
    }

    private func extractDate(from text: String) -> Date? {
        // Common date formats
        let datePatterns: [(String, String)] = [
            ("\\d{1,2}/\\d{1,2}/\\d{2,4}", "M/d/yy"),      // 1/15/24 or 01/15/2024
            ("\\d{1,2}-\\d{1,2}-\\d{2,4}", "M-d-yy"),      // 1-15-24
            ("\\d{4}-\\d{2}-\\d{2}", "yyyy-MM-dd"),        // 2024-01-15
            ("[A-Za-z]{3}\\s+\\d{1,2},?\\s+\\d{4}", "MMM d, yyyy"), // Jan 15, 2024
            ("\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4}", "d MMM yyyy")     // 15 Jan 2024
        ]

        for (pattern, format) in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let dateString = String(text[range])
                let formatter = DateFormatter()
                formatter.dateFormat = format

                // Try with 2-digit and 4-digit years
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Try alternate formats
                let alternateFormats = ["M/d/yyyy", "MM/dd/yyyy", "M/d/yy", "MM/dd/yy"]
                for altFormat in alternateFormats {
                    formatter.dateFormat = altFormat
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    private func guessCategory(merchant: String?, text: String) -> ExpenseCategory {
        let searchText = (merchant ?? "").lowercased() + " " + text.lowercased()

        // Travel
        if searchText.contains("airline") || searchText.contains("flight") ||
           searchText.contains("hotel") || searchText.contains("uber") ||
           searchText.contains("lyft") || searchText.contains("taxi") ||
           searchText.contains("rental car") || searchText.contains("airbnb") {
            return .travel
        }

        // Meals
        if searchText.contains("restaurant") || searchText.contains("cafe") ||
           searchText.contains("coffee") || searchText.contains("starbucks") ||
           searchText.contains("mcdonald") || searchText.contains("food") ||
           searchText.contains("dining") || searchText.contains("bar") ||
           searchText.contains("pizza") || searchText.contains("burger") {
            return .meals
        }

        // Software
        if searchText.contains("software") || searchText.contains("subscription") ||
           searchText.contains("adobe") || searchText.contains("microsoft") ||
           searchText.contains("google") || searchText.contains("apple") ||
           searchText.contains("aws") || searchText.contains("cloud") {
            return .software
        }

        // Hardware
        if searchText.contains("apple store") || searchText.contains("best buy") ||
           searchText.contains("computer") || searchText.contains("laptop") ||
           searchText.contains("electronics") || searchText.contains("phone") {
            return .hardware
        }

        // Office Supplies
        if searchText.contains("staples") || searchText.contains("office depot") ||
           searchText.contains("office max") || searchText.contains("supplies") ||
           searchText.contains("paper") || searchText.contains("ink") {
            return .officeSupplies
        }

        // Utilities
        if searchText.contains("electric") || searchText.contains("gas") ||
           searchText.contains("water") || searchText.contains("internet") ||
           searchText.contains("phone bill") || searchText.contains("utility") {
            return .utilities
        }

        // Marketing
        if searchText.contains("advertising") || searchText.contains("marketing") ||
           searchText.contains("facebook ads") || searchText.contains("google ads") ||
           searchText.contains("promotion") {
            return .marketing
        }

        return .other
    }

    private func extractItems(from lines: [String]) -> [String] {
        var items: [String] = []

        for line in lines {
            // Skip header/footer lines
            let uppercased = line.uppercased()
            if uppercased.contains("TOTAL") || uppercased.contains("SUBTOTAL") ||
               uppercased.contains("TAX") || uppercased.contains("CHANGE") ||
               uppercased.contains("CASH") || uppercased.contains("CARD") ||
               uppercased.contains("THANK") || uppercased.contains("RECEIPT") {
                continue
            }

            // Lines with prices are likely items
            if extractAmount(from: line) != nil && line.count > 3 {
                // Clean up the item description
                let item = line
                    .replacingOccurrences(of: "\\$[0-9,]+\\.?[0-9]*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)

                if !item.isEmpty && item.count > 2 {
                    items.append(item)
                }
            }
        }

        return Array(items.prefix(10)) // Limit to first 10 items
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension ReceiptScanner: VNDocumentCameraViewControllerDelegate {

    nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        Task { @MainActor in
            controller.dismiss(animated: true)

            guard scan.pageCount > 0 else {
                let error = NSError(
                    domain: "ReceiptScanner",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "No pages scanned"]
                )
                delegate?.receiptScanner(self, didFailWith: error)
                return
            }

            // Process the first page (usually receipts are single page)
            let image = scan.imageOfPage(at: 0)

            do {
                let recognizedText = try await recognizeText(from: image)
                let receiptData = parseReceipt(from: recognizedText)
                delegate?.receiptScanner(self, didFinishWith: receiptData)
            } catch {
                delegate?.receiptScanner(self, didFailWith: error)
            }
        }
    }

    nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        Task { @MainActor in
            controller.dismiss(animated: true)
            delegate?.receiptScannerDidCancel(self)
        }
    }

    nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        Task { @MainActor in
            controller.dismiss(animated: true)
            delegate?.receiptScanner(self, didFailWith: error)
        }
    }
}
