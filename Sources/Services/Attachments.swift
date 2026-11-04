import Foundation
import UIKit

/// Receipt photos live in the app's Documents folder. Nothing is uploaded.
enum Attachments {
    private static var folder: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Receipts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func save(imageData: Data, name: String) -> String {
        let filename = "\(name)-\(UUID().uuidString.prefix(8)).jpg"
        let url = folder.appendingPathComponent(filename)
        let compressed = UIImage(data: imageData)?.jpegData(compressionQuality: 0.75) ?? imageData
        do {
            try compressed.write(to: url, options: .atomic)
            return filename
        } catch {
            return ""
        }
    }

    static func url(for filename: String) -> URL? {
        guard !filename.isEmpty else { return nil }
        let url = folder.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func delete(_ filename: String) {
        guard let url = url(for: filename) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
