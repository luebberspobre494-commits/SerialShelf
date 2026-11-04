import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query(sort: \GearItem.createdAt) private var items: [GearItem]

    private var totalValue: Double {
        items.map(\.value).reduce(0, +)
    }

    private var coveredValue: Double {
        items.filter { $0.warrantyState != .expired }.map(\.value).reduce(0, +)
    }

    private var expiringCount: Int {
        items.filter { $0.warrantyState == .endingSoon }.count
    }

    private var claimedCount: Int {
        items.filter(\.claimed).count
    }

    private var byCategory: [(category: ItemCategory, count: Int)] {
        ItemCategory.allCases.compactMap { category in
            let count = items.filter { $0.itemCategory == category }.count
            return count > 0 ? (category, count) : nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    categoryCard
                    exportCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reports")
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            HStack {
                stat("Devices", "\(items.count)")
                Divider().frame(height: 36)
                stat("Expiring", "\(expiringCount)")
                Divider().frame(height: 36)
                stat("Claims", "\(claimedCount)")
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(money(totalValue))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Still covered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(money(coveredValue))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.green)
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Devices by category")
                .font(.subheadline.weight(.semibold))
            if byCategory.isEmpty {
                Text("No data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(byCategory, id: \.category.id) { entry in
                        BarMark(
                            x: .value("Count", entry.count),
                            y: .value("Category", entry.category.rawValue)
                        )
                        .foregroundStyle(Color.accentColor)
                        .cornerRadius(6)
                    }
                }
                .frame(height: CGFloat(byCategory.count) * 34 + 20)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export")
                .font(.subheadline.weight(.semibold))
            Text("A CSV with every device, serial number and warranty date. Useful for an insurance claim or when selling.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let url = CSV.writeExport(items) {
                ShareLink(item: url) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func money(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
