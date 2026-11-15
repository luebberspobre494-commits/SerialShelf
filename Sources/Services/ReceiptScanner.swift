import Foundation
import UIKit
import Vision

/// Whatever we could pull out of a photo of a paper receipt.
struct ReceiptFields {
    var merchant: String?
    var amount: Double?
    var date: Date?

    var isEmpty: Bool { merchant == nil && amount == nil && date == nil }
}

/// Reads a receipt photo on device and guesses the merchant, the total and the
/// purchase date. The point is that the user never retypes numbers off a
/// crumpled receipt, which no other warranty tracker in this category does.
enum ReceiptScanner {
    static func scan(_ data: Data) async -> ReceiptFields {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return ReceiptFields()
        }
        let lines = await recognize(in: cgImage)
        return parse(lines)
    }

    private static func recognize(in cgImage: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let observations = (request.results ?? [])
                        .compactMap { $0 as? VNRecognizedTextObservation }
                    let text = observations.compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: text)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private static func parse(_ lines: [String]) -> ReceiptFields {
        let joined = lines.joined(separator: "\n")
        return ReceiptFields(
            merchant: merchant(from: lines),
            amount: amount(in: joined),
            date: date(in: joined)
        )
    }

    // MARK: - Total

    /// Prefers a number that follows a word like "total", otherwise the largest
    /// money-looking number on the page.
    private static func amount(in text: String) -> Double? {
        let labelled = try? NSRegularExpression(
            pattern: "(?i)(?:grand total|total|amount due|balance due|amount)[^0-9\n]{0,18}([0-9][0-9,]*(?:\.[0-9]{2}))"
        )
        if let match = labelled?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ), match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text),
           let value = number(String(text[range])) {
            return value
        }

        let any = try? NSRegularExpression(pattern: "[0-9][0-9,]*\.[0-9]{2}")
        let matches = any?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        let values = matches.compactMap { match -> Double? in
            guard let range = Range(match.range, in: text) else { return nil }
            return number(String(text[range]))
        }
        return values.max()
    }

    private static func number(_ raw: String) -> Double? {
        Double(raw.replacingOccurrences(of: ",", with: ""))
    }

    // MARK: - Date

    private static let datePatterns = [
        "MM/dd/yyyy", "MM/dd/yy", "dd/MM/yyyy", "dd/MM/yy",
        "yyyy-MM-dd", "MMM d, yyyy", "d MMM yyyy", "MMM d yyyy",
        "MMMM d, yyyy", "d MMMM yyyy"
    ]

    private static func date(in text: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        if let found = detector?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ), let value = found.date {
            return value
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for pattern in datePatterns {
            formatter.dateFormat = pattern
            let parts = text.split(whereSeparator: { $0 == "\n" || $0 == "/" })
            for part in parts {
                let candidate = String(part).trimmingCharacters(in: .whitespaces)
                if let parsed = formatter.date(from: candidate) {
                    return parsed
                }
            }
        }
        return nil
    }

    // MARK: - Merchant

    private static let noise = [
        "receipt", "invoice", "total", "subtotal", "tax", "vat", "tel", "phone",
        "date", "time", "cashier", "thank", "welcome", "order", "item", "qty",
        "change", "cash", "card", "customer", "store"
    ]

    private static func merchant(from lines: [String]) -> String? {
        for raw in lines.prefix(8) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count >= 3, line.count <= 40 else { continue }
            guard line.contains(where: { $0.isLetter }) else { continue }
            guard line.rangeOfCharacter(from: .decimalDigits) == nil else { continue }

            let lower = line.lowercased()
            if noise.contains(where: { lower.contains($0) }) { continue }
            return line
        }
        return nil
    }
}
