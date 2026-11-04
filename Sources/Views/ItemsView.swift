import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ItemsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GearItem.createdAt, order: .reverse) private var items: [GearItem]

    @State private var search = ""
    @State private var filter: ItemCategory?
    @State private var sort: SortOption = .newest
    @State private var showingAdd = false
    @State private var showingImport = false
    @State private var importedCount: Int?

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case name = "Name"
        case expiry = "Warranty end"

        var id: String { rawValue }
    }

    private var filtered: [GearItem] {
        var result = items

        if let filter {
            result = result.filter { $0.itemCategory == filter }
        }

        let needle = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !needle.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(needle)
                    || $0.brand.lowercased().contains(needle)
                    || $0.serial.lowercased().contains(needle)
            }
        }

        switch sort {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .expiry:
            result.sort { $0.warrantyEnd < $1.warrantyEnd }
        }
        return result
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
            .navigationTitle("SerialShelf")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    searchBar
                    categoryBar
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddItemView()
            }
            .fileImporter(
                isPresented: $showingImport,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Imported", isPresented: Binding(
                get: { importedCount != nil },
                set: { if !$0 { importedCount = nil } }
            )) {
                Button("OK") { importedCount = nil }
            } message: {
                Text("\(importedCount ?? 0) items added from the CSV file.")
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Search name, brand or serial", text: $search)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(.bar)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", selected: filter == nil) { filter = nil }
                ForEach(ItemCategory.allCases) { category in
                    chip(title: category.rawValue, selected: filter == category) {
                        filter = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func chip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var list: some View {
        List {
            Section {
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
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView("No matches", systemImage: "magnifyingglass")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No devices yet", systemImage: "shippingbox")
        } description: {
            Text("Save a serial number and purchase date. We remind you once, 30 days before the warranty ends.")
        } actions: {
            Button("Add first device") { showingAdd = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = filtered[index]
            Reminders.remove(for: item)
            Attachments.delete(item.receiptFilename)
            context.delete(item)
        }
        try? context.save()
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else { return }

        let rows = CSV.parse(text)
        for row in rows {
            let item = GearItem(
                name: row.name,
                brand: row.brand,
                serial: row.serial,
                purchaseDate: row.purchaseDate,
                warrantyMonths: row.warrantyMonths,
                notes: row.notes,
                category: row.category,
                value: row.value
            )
            context.insert(item)
        }
        try? context.save()
        importedCount = rows.count
    }
}

struct ItemRow: View {
    let item: GearItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.itemCategory.symbol)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
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
                Text(item.statusText)
                    .font(.caption2)
                    .foregroundStyle(tint)
            }

            Spacer()

            if item.claimed {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    private var tint: Color {
        switch item.warrantyState {
        case .active: return .secondary
        case .endingSoon: return .orange
        case .expired: return .red
        }
    }
}
