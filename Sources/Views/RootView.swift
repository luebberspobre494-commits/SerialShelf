import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GearItem.createdAt, order: .reverse) private var items: [GearItem]

    @State private var showingAdd = false
    @State private var search = ""

    private var filtered: [GearItem] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return items }
        let needle = query.lowercased()
        return items.filter {
            $0.name.lowercased().contains(needle)
                || $0.brand.lowercased().contains(needle)
                || $0.serial.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("序列号")
            .searchable(text: $search, prompt: "搜名称、品牌或序列号")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddItemView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有记录", systemImage: "shippingbox")
        } description: {
            Text("记下设备的序列号和购买日期。保修到期前 30 天，会提醒你一次。")
        } actions: {
            Button("添加第一台") {
                showingAdd = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var list: some View {
        List {
            ForEach(filtered) { item in
                NavigationLink {
                    ItemDetailView(item: item)
                } label: {
                    ItemRow(item: item)
                }
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(at offsets: IndexSet) {
        let doomed = offsets.map { filtered[$0] }
        for item in doomed {
            Reminders.remove(for: item)
            context.delete(item)
        }
        try? context.save()
    }
}

struct ItemRow: View {
    let item: GearItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.headline)

            if !item.brand.isEmpty {
                Text(item.brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !item.serial.isEmpty {
                Text(item.serial)
                    .font(.caption)
                    .monospaced()
                    .foregroundStyle(.secondary)
            }

            Text(status)
                .font(.caption2)
                .foregroundStyle(tint)
        }
        .padding(.vertical, 2)
    }

    private var status: String {
        switch item.warrantyState {
        case .active:
            return "保修中 · 还剩 \(item.daysLeft) 天"
        case .endingSoon:
            return "即将到期 · 还剩 \(item.daysLeft) 天"
        case .expired:
            return "已过期 \(abs(item.daysLeft)) 天"
        }
    }

    private var tint: Color {
        switch item.warrantyState {
        case .active:
            return .secondary
        case .endingSoon:
            return .orange
        case .expired:
            return .red
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: GearItem.self, inMemory: true)
}
