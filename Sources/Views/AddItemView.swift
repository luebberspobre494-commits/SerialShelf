import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var serial = ""
    @State private var category: ItemCategory = .electronics
    @State private var value = ""
    @State private var purchaseDate = Date.now
    @State private var warrantyMonths = 12
    @State private var notes = ""

    @State private var labelPhoto: PhotosPickerItem?
    @State private var receiptPhoto: PhotosPickerItem?
    @State private var receiptPreview: Data?
    @State private var candidates: [String] = []
    @State private var scanning = false
    @State private var scanMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Device") {
                    TextField("Name, e.g. MacBook Pro", text: $name)
                    TextField("Brand", text: $brand)
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { item in
                            Label(item.rawValue, systemImage: item.symbol).tag(item)
                        }
                    }
                    HStack {
                        Text("Value")
                        Spacer()
                        TextField("0.00", text: $value)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                serialSection
                warrantySection
                receiptSection

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("New Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: labelPhoto) { _, newValue in
                guard let newValue else { return }
                Task { await scan(newValue) }
            }
            .onChange(of: receiptPhoto) { _, newValue in
                guard let newValue else { return }
                Task { receiptPreview = try? await newValue.loadTransferable(type: Data.self) }
            }
        }
    }

    private var serialSection: some View {
        Section {
            TextField("Serial number", text: $serial)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.body.monospaced())

            PhotosPicker(selection: $labelPhoto, matching: .images) {
                Label("Read from photo", systemImage: "text.viewfinder")
            }

            if scanning {
                ProgressView("Scanning...")
            }

            if let scanMessage {
                Text(scanMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(candidates.prefix(5), id: \.self) { candidate in
                Button {
                    serial = candidate
                    candidates = []
                    scanMessage = nil
                } label: {
                    Text(candidate)
                        .font(.footnote.monospaced())
                }
            }
        } header: {
            Text("Serial number")
        } footer: {
            Text("Pick a photo of the label. Text recognition runs on this device; the photo is never uploaded.")
        }
    }

    private var warrantySection: some View {
        Section("Warranty") {
            DatePicker("Purchased", selection: $purchaseDate, displayedComponents: .date)
            Stepper(value: $warrantyMonths, in: 0...60) {
                Text("Warranty \(warrantyMonths) months")
            }
        }
    }

    private var receiptSection: some View {
        Section {
            PhotosPicker(selection: $receiptPhoto, matching: .images) {
                Label(receiptPreview == nil ? "Attach receipt" : "Change receipt", systemImage: "doc.viewfinder")
            }
            if let receiptPreview, let image = UIImage(data: receiptPreview) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        } header: {
            Text("Receipt")
        } footer: {
            Text("Stored on this device only. Handy when a warranty claim needs proof of purchase.")
        }
    }

    private func scan(_ pick: PhotosPickerItem) async {
        scanning = true
        scanMessage = nil
        defer { scanning = false }

        guard let data = try? await pick.loadTransferable(type: Data.self) else {
            scanMessage = "Could not read that photo. Try another one."
            return
        }

        let found = await SerialScanner.candidates(from: data)
        candidates = found
        if let best = found.first {
            serial = best
        } else {
            scanMessage = "No serial-like text found. You can type it in."
        }
    }

    private func save() {
        var receiptName = ""
        if let receiptPreview {
            receiptName = Attachments.save(imageData: receiptPreview, name: name)
        }

        let item = GearItem(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces),
            serial: serial.trimmingCharacters(in: .whitespaces),
            purchaseDate: purchaseDate,
            warrantyMonths: warrantyMonths,
            notes: notes,
            category: category.rawValue,
            value: Double(value) ?? 0,
            receiptFilename: receiptName
        )
        context.insert(item)
        try? context.save()

        Task {
            _ = await Reminders.requestAuthorization()
            await Reminders.reschedule(for: item)
        }
        dismiss()
    }
}
