import Foundation
import UIKit
import Vision

/// Pulls serial-number-looking text out of a photo using the on-device Vision
/// text recogniser. Nothing leaves the device.
enum SerialScanner {
    /// Text lines ranked by how much they look like a serial number, best first.
    static func candidates(from data: Data) async -> [String] {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return []
        }
        let lines = await recognizeText(in: cgImage)
        return rank(lines)
    }

    private static func recognizeText(in cgImage: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                // Labels are usually printed in caps; correction would "fix" a serial.
                request.usesLanguageCorrection = false

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let observations = (request.results ?? []).compactMap { $0 as? VNRecognizedTextObservation }
                    let text = observations.compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: text)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private static let labels = ["SERIAL", "S/N", "SN", "IMEI", "SERIAL", "SN"]

    private static func rank(_ lines: [String]) -> [String] {
        var scored: [(text: String, score: Int)] = []

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count >= 5, line.count <= 40 else { continue }

            let hasDigit = line.contains { $0.isNumber }
            let hasLetter = line.contains { $0.isLetter }
            // A serial mixes letters and digits; a pure number is usually a date or a price.
            guard hasDigit && hasLetter else { continue }

            let upper = line.uppercased()
            var score = 0
            if labels.contains(where: { upper.contains($0) }) { score += 3 }
            if line.count >= 8 { score += 1 }
            if line.contains(" ") { score -= 2 }
            if line.contains(":") { score -= 1 }

            scored.append((line, score))
        }

        var seen = Set<String>()
        return scored
            .sorted { $0.score > $1.score }
            .map(\.text)
            .filter { seen.insert($0).inserted }
    }
}
