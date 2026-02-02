//
//  ReceiptScannerView.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import SwiftUI
import UIKit
import Vision
import VisionKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    var onScanComplete: (ScannedReceiptData) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let scannerVC = VNDocumentCameraViewController()
        scannerVC.delegate = context.coordinator

        let navController = UINavigationController(rootViewController: scannerVC)
        navController.isNavigationBarHidden = true
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ReceiptScannerView
        private let scanner = ReceiptScanner()

        init(parent: ReceiptScannerView) {
            self.parent = parent
            super.init()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                parent.dismiss()
                return
            }

            let image = scan.imageOfPage(at: 0)

            Task { @MainActor in
                do {
                    let text = try await recognizeText(from: image)
                    let data = parseReceipt(from: text)
                    parent.onScanComplete(data)
                } catch {
                    print("Receipt scanning failed: \(error)")
                }
                parent.dismiss()
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scanner error: \(error)")
            parent.dismiss()
        }

        // MARK: - Text Recognition

        private func recognizeText(from image: UIImage) async throws -> String {
            guard let cgImage = image.cgImage else {
                return ""
            }

            return try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: "")
                        return
                    }

                    let text = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")

                    continuation.resume(returning: text)
                }

                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try handler.perform([request])
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

            data.merchant = extractMerchant(from: lines)
            data.amount = extractTotal(from: lines)
            data.date = extractDate(from: text)
            data.category = guessCategory(merchant: data.merchant, text: text)
            data.items = extractItems(from: lines)

            return data
        }

        private func extractMerchant(from lines: [String]) -> String? {
            for line in lines.prefix(5) {
                if line.contains("RECEIPT") || line.contains("INVOICE") { continue }
                if line.contains("/") && line.count < 15 { continue }
                if line.first?.isNumber == true && line.contains("-") { continue }

                if line.count > 2 && line.count < 50 {
                    let letterCount = line.filter { $0.isLetter || $0.isWhitespace }.count
                    if Double(letterCount) / Double(line.count) > 0.5 {
                        return line
                    }
                }
            }
            return lines.first
        }

        private func extractTotal(from lines: [String]) -> Double? {
            let totalPatterns = ["TOTAL", "GRAND TOTAL", "AMOUNT DUE", "BALANCE DUE", "SUBTOTAL"]

            for line in lines.reversed() {
                let uppercased = line.uppercased()
                for pattern in totalPatterns {
                    if uppercased.contains(pattern) {
                        if let amount = extractAmount(from: line) {
                            return amount
                        }
                    }
                }
            }

            var amounts: [Double] = []
            for line in lines {
                if let amount = extractAmount(from: line) {
                    amounts.append(amount)
                }
            }
            return amounts.max()
        }

        private func extractAmount(from text: String) -> Double? {
            let patterns = [
                "\\$\\s*([0-9,]+\\.?[0-9]*)",
                "([0-9,]+\\.[0-9]{2})(?:\\s|$)",
                "USD\\s*([0-9,]+\\.?[0-9]*)"
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
            let datePatterns: [(String, String)] = [
                ("\\d{1,2}/\\d{1,2}/\\d{2,4}", "M/d/yy"),
                ("\\d{1,2}-\\d{1,2}-\\d{2,4}", "M-d-yy"),
                ("\\d{4}-\\d{2}-\\d{2}", "yyyy-MM-dd"),
                ("[A-Za-z]{3}\\s+\\d{1,2},?\\s+\\d{4}", "MMM d, yyyy")
            ]

            for (pattern, format) in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
                   let range = Range(match.range, in: text) {
                    let dateString = String(text[range])
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
            return nil
        }

        private func guessCategory(merchant: String?, text: String) -> ExpenseCategory {
            let searchText = (merchant ?? "").lowercased() + " " + text.lowercased()

            if searchText.contains("airline") || searchText.contains("flight") ||
               searchText.contains("hotel") || searchText.contains("uber") ||
               searchText.contains("lyft") || searchText.contains("taxi") {
                return .travel
            }

            if searchText.contains("restaurant") || searchText.contains("cafe") ||
               searchText.contains("coffee") || searchText.contains("starbucks") ||
               searchText.contains("mcdonald") || searchText.contains("food") {
                return .meals
            }

            if searchText.contains("software") || searchText.contains("subscription") ||
               searchText.contains("adobe") || searchText.contains("microsoft") {
                return .software
            }

            if searchText.contains("apple store") || searchText.contains("best buy") ||
               searchText.contains("computer") || searchText.contains("electronics") {
                return .hardware
            }

            if searchText.contains("staples") || searchText.contains("office depot") ||
               searchText.contains("supplies") || searchText.contains("paper") {
                return .officeSupplies
            }

            if searchText.contains("electric") || searchText.contains("gas") ||
               searchText.contains("water") || searchText.contains("internet") {
                return .utilities
            }

            return .other
        }

        private func extractItems(from lines: [String]) -> [String] {
            var items: [String] = []

            for line in lines {
                let uppercased = line.uppercased()
                if uppercased.contains("TOTAL") || uppercased.contains("TAX") ||
                   uppercased.contains("CHANGE") || uppercased.contains("CASH") { continue }

                if extractAmount(from: line) != nil && line.count > 3 {
                    let item = line
                        .replacingOccurrences(of: "\\$[0-9,]+\\.?[0-9]*", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)
                    if !item.isEmpty && item.count > 2 {
                        items.append(item)
                    }
                }
            }

            return Array(items.prefix(10))
        }
    }
}
