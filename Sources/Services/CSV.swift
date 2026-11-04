import Foundation

/// Plain comma separated import and export. Columns:
/// name, brand, serial, category, purchase date (yyyy-MM-dd), warranty months, value, notes
enum CSV {
    static let header = "name,brand,serial,category,purchaseDate,warrantyMonths,value,notes"

    static func export(_ items: [GearItem]) -> String {
        var rows = [header]
        for item in items {
            let fields = [
                item.name,
                item.brand,
                item.serial,
                item.category,
                dateFormatter.string(from: item.purchaseDate),
                String(item.warrantyMonths),
                item.value > 0 ? String(format: "%.2f", item.value) : "",
                item.notes
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func writeExport(_ items: [GearItem]) -> URL? {
        let content = export(items)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SerialShelf-export.csv")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    struct ParsedRow {
        let name: String
        let brand: String
        let serial: String
        let category: String
        let purchaseDate: Date
        let warrantyMonths: Int
        let value: Double
        let notes: String
    }

    static func parse(_ text: String) -> [ParsedRow] {
        var rows: [ParsedRow] = []
        for (index, line) in text.split(whereSeparator: \.isNewline).enumerated() {
            let raw = String(line)
            if index == 0 && raw.lowercased().hasPrefix("name") { continue }
            let cells = split(raw)
            guard let name = cells.first, !name.isEmpty else { continue }

            func cell(_ i: Int) -> String { i < cells.count ? cells[i] : "" }

            let months = Int(cell(5)) ?? 12
            let parsedDate = dateFormatter.date(from: cell(4)) ?? .now
            rows.append(
                ParsedRow(
                    name: name,
                    brand: cell(1),
                    serial: cell(2),
                    category: ItemCategory(rawValue: cell(3))?.rawValue ?? ItemCategory.other.rawValue,
                    purchaseDate: parsedDate,
                    warrantyMonths: months,
                    value: Double(cell(6)) ?? 0,
                    notes: cell(7)
                )
            )
        }
        return rows
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static func split(_ line: String) -> [String] {
        var cells: [String] = []
        var current = ""
        var insideQuotes = false
        for character in line {
            if character == "\"" {
                insideQuotes.toggle()
            } else if character == "," && !insideQuotes {
                cells.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        cells.append(current)
        return cells.map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
