import Foundation
import SwiftData

/// One physical thing you own: its serial number, when you bought it, how long
/// the warranty runs. Everything stays on the device — there is no account and
/// no network code in this app.
@Model
final class GearItem {
    var name: String
    var brand: String
    var serial: String
    var purchaseDate: Date
    var warrantyMonths: Int
    var notes: String
    var createdAt: Date

    init(
        name: String,
        brand: String = "",
        serial: String = "",
        purchaseDate: Date = .now,
        warrantyMonths: Int = 12,
        notes: String = ""
    ) {
        self.name = name
        self.brand = brand
        self.serial = serial
        self.purchaseDate = purchaseDate
        self.warrantyMonths = warrantyMonths
        self.notes = notes
        self.createdAt = .now
    }

    var warrantyEnd: Date {
        Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) ?? purchaseDate
    }

    /// Whole days until the warranty ends; negative once it has passed.
    var daysLeft: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: warrantyEnd)
        ).day ?? 0
    }

    var warrantyState: WarrantyState {
        if daysLeft < 0 { return .expired }
        if daysLeft <= 30 { return .endingSoon }
        return .active
    }
}

enum WarrantyState: Equatable {
    case active
    case endingSoon
    case expired

    var label: String {
        switch self {
        case .active:
            return "保修中"
        case .endingSoon:
            return "即将到期"
        case .expired:
            return "已过期"
        }
    }
}
