import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct ItemDetailView: View {
    @Bindable var item: GearItem

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirm = false
    @State private var newReceipt: PhotosPickerItem?

    var body: some View {
        Form {
            Section("Device") {
                TextField("Name", text: $item.name)
                TextField("Brand", text: $item.brand)
                Picker("Category", selection: Binding(
                    get: { item.itemCategory },
                    set: { item.itemCategory = $0 }
                )) {
                    ForEach(ItemCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.symbol).tag(category)
                    }
                }
                HStack {
                    Text("Value")
                    Spacer()
                    TextField("0.00", text: Binding(
                        get: { item.value > 0 ? String(format: "%.2f", item.value) : "" },
                        set: { item.value = Double($0) ?? 0 }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
            }

            Section {
                TextField("Serial number", text: $item.serial)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())
                if !item.serial.isEmpty {
                    Button {
                        UIPasteboard.general.string = item.serial
                    } label: {
                        Label("Copy serial number", systemImage: "doc.on.doc")
                    }
                }
            } header: {
                Text("Serial number")
            }

            warrantySection
            receiptSection
            claimSection

            Section("Notes") {
                TextField("Optional", text: $item.notes, axis: .vertical)
                    .lineLimit(2...6)
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("Delete this device", systemImage: "trash")
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: item.warrantyEnd) { _, _ in
            Task { await Reminders.reschedule(for: item) }
        }
        .onChange(of: newReceipt) { _, value in
            guard let value else { return }
            Task {
                if let data = try? await value.loadTransferable(type: Data.self) {
                    Attachments.delete(item.receiptFilename)
                    item.receiptFilename = Attachments.save(imageData: data, name: item.name)
                }
            }
        }
        .confirmationDialog("This cannot be undone", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Reminders.remove(for: item)
                Attachments.delete(item.receiptFilename)
                context.delete(item)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var warrantySection: some View {
        Section("Warranty") {
            DatePicker("Purchased", selection: $item.purchaseDate, displayedComponents: .date)
            Stepper(value: $item.warrantyMonths, in: 0...60) {
                Text("Warranty \(item.warrantyMonths) months")
            }
            LabeledContent("Ends") {
                Text(item.warrantyEnd, format: .dateTime.year().month().day())
            }
            LabeledContent("Status") {
                Text(item.statusText)
                    .foregroundStyle(tint)
            }
        }
    }

    private var receiptSection: some View {
        Section {
            if let url = Attachments.url(for: item.receiptFilename),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            PhotosPicker(selection: $newReceipt, matching: .images) {
                Label(item.receiptFilename.isEmpty ? "Attach receipt" : "Replace receipt", systemImage: "doc.viewfinder")
            }
            if !item.receiptFilename.isEmpty {
                Button(role: .destructive) {
                    Attachments.delete(item.receiptFilename)
                    item.receiptFilename = ""
                } label: {
                    Label("Remove receipt", systemImage: "trash")
                }
            }
        } header: {
            Text("Receipt")
        }
    }

    private var claimSection: some View {
        Section {
            Toggle("Warranty claim filed", isOn: $item.claimed)
            if item.claimed {
                DatePicker("Claim date", selection: Binding(
                    get: { item.claimDate ?? .now },
                    set: { item.claimDate = $0 }
                ), displayedComponents: .date)
                TextField("What happened?", text: $item.claimNote, axis: .vertical)
                    .lineLimit(2...4)
            }
        } header: {
            Text("Claim")
        } footer: {
            Text("Track what you sent back and when, so a stalled claim is easy to chase.")
        }
    }

    private var tint: Color {
        switch item.warrantyState {
        case .active: return .secondary
        case .endingSoon: return .orange
        case .expired: return .red
        }
    }
}
