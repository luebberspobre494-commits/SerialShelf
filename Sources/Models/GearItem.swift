import Foundation
import SwiftData

/// One physical thing you own: its serial number, when you bought it, how long
/// the warranty runs. Everything stays on the device - there is no account and
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

    var category: String
    var value: Double
    var receiptFilename: String
    var claimed: Bool
    var claimDate: Date?
    var claimNote: String

    init(
        name: String,
        brand: String = "",
        serial: String = "",
        purchaseDate: Date = .now,
        warrantyMonths: Int = 12,
        notes: String = "",
        category: String = ItemCategory.other.rawValue,
        value: Double = 0,
        receiptFilename: String = "",
        claimed: Bool = false,
        claimDate: Date? = nil,
        claimNote: String = ""
    ) {
        self.name = name
        self.brand = brand
        self.serial = serial
        self.purchaseDate = purchaseDate
        self.warrantyMonths = warrantyMonths
        self.notes = notes
        self.createdAt = .now
        self.category = category
        self.value = value
        self.receiptFilename = receiptFilename
        self.claimed = claimed
        self.claimDate = claimDate
        self.claimNote = claimNote
    }

    var itemCategory: ItemCategory {
        get { ItemCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
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

    var statusText: String {
        switch warrantyState {
        case .active:
            return "In warranty | \(daysLeft) days left"
        case .endingSoon:
            return "Ending soon | \(daysLeft) days left"
        case .expired:
            return "Expired \(abs(daysLeft)) days ago"
        }
    }
}

enum WarrantyState: Equatable {
    case active
    case endingSoon
    case expired

    var label: String {
        switch self {
        case .active: return "In warranty"
        case .endingSoon: return "Ending soon"
        case .expired: return "Expired"
        }
    }
}
