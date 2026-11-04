import SwiftUI
import SwiftData

struct WarrantyView: View {
    @Query(sort: \GearItem.warrantyMonths) private var items: [GearItem]
    @Environment(\.modelContext) private var context

    private var expiring: [GearItem] {
        items.filter { $0.warrantyState == .endingSoon }.sorted { $0.warrantyEnd < $1.warrantyEnd }
    }

    private var active: [GearItem] {
        items.filter { $0.warrantyState == .active }.sorted { $0.warrantyEnd < $1.warrantyEnd }
    }

    private var expired: [GearItem] {
        items.filter { $0.warrantyState == .expired }.sorted { $0.warrantyEnd > $1.warrantyEnd }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing to watch yet",
                        systemImage: "shield.lefthalf.filled",
                        description: Text("Add a device and its warranty shows up here.")
                    )
                } else {
                    List {
                        section("Ending soon", items: expiring, tint: .orange)
                        section("In warranty", items: active, tint: .green)
                        section("Expired", items: expired, tint: .red)
                    }
                }
            }
            .navigationTitle("Warranty")
        }
    }

    @ViewBuilder
    private func section(_ title: String, items rows: [GearItem], tint: Color) -> some View {
        if !rows.isEmpty {
            Section {
                ForEach(rows) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.itemCategory.symbol)
                            .foregroundStyle(tint)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                            Text("Ends \(item.warrantyEnd, format: .dateTime.year().month().day())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            item.claimed.toggle()
                            if item.claimed { item.claimDate = .now }
                            try? context.save()
                        } label: {
                            Image(systemName: item.claimed ? "checkmark.seal.fill" : "seal")
                                .foregroundStyle(item.claimed ? Color.orange : Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(rows.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
