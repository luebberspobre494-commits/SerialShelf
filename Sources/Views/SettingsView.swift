import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [GearItem]

    @State private var showingImport = false
    @State private var importedCount: Int?
    @State private var reminderStatus = "Not requested"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await enableReminders() }
                    } label: {
                        Label("Allow warranty reminders", systemImage: "bell.badge")
                    }
                    LabeledContent("Reminder", value: reminderStatus)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("One notification per device, 30 days before the warranty ends. Nothing leaves your phone.")
                }

                Section {
                    if let url = CSV.writeExport(items) {
                        ShareLink(item: url) {
                            Label("Export all devices (CSV)", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button {
                        showingImport = true
                    } label: {
                        Label("Import from CSV", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Columns: name, brand, serial, category, purchaseDate, warrantyMonths, value, notes")
                }

                Section {
                    LabeledContent("Devices", value: "\(items.count)")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                } header: {
                    Text("About")
                } footer: {
                    Text("SerialShelf keeps every serial number on this device. No account, no analytics, no network calls.")
                }
            }
            .navigationTitle("Settings")
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
                Text("\(importedCount ?? 0) devices added.")
            }
        }
    }

    private func enableReminders() async {
        let granted = await Reminders.requestAuthorization()
        reminderStatus = granted ? "Allowed" : "Denied"
        guard granted else { return }
        for item in items {
            await Reminders.reschedule(for: item)
        }
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
