import XCTest
@testable import SerialShelf

final class SerialShelfTests: XCTestCase {
    func testWarrantyEndAddsWholeMonths() {
        let purchase = Date(timeIntervalSince1970: 1_700_000_000)
        let item = GearItem(name: "Test", purchaseDate: purchase, warrantyMonths: 12)
        let expected = Calendar.current.date(byAdding: .month, value: 12, to: purchase)
        XCTAssertEqual(item.warrantyEnd, expected)
    }

    func testZeroMonthsMeansExpiredImmediately() {
        let purchase = Date.now.addingTimeInterval(-86_400 * 10)
        let item = GearItem(name: "No warranty", purchaseDate: purchase, warrantyMonths: 0)
        XCTAssertEqual(item.warrantyState, .expired)
        XCTAssertLessThan(item.daysLeft, 0)
    }

    func testEndingSoonWindow() {
        let purchase = Date.now
        // 13 months of warranty puts the expiry ~30 days out.
        let item = GearItem(name: "Almost up", purchaseDate: purchase, warrantyMonths: 13)
        XCTAssertEqual(item.warrantyState, .active)

        let short = GearItem(name: "Ending", purchaseDate: purchase, warrantyMonths: 12)
        short.purchaseDate = Calendar.current.date(byAdding: .day, value: -345, to: .now) ?? .now
        XCTAssertEqual(short.warrantyState, .endingSoon)
    }
}
