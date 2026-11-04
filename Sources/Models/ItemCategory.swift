import Foundation

enum ItemCategory: String, CaseIterable, Identifiable {
    case electronics = "Electronics"
    case appliance = "Appliance"
    case tools = "Tools"
    case vehicle = "Vehicle"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .electronics: return "desktopcomputer"
        case .appliance: return "washer"
        case .tools: return "hammer"
        case .vehicle: return "car"
        case .other: return "shippingbox"
        }
    }
}
