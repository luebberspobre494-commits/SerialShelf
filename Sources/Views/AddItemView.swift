import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var serial = ""
    @State private var purchaseDate = Date.now
    @State private var warrantyMonths = 12
    @State private var notes = ""

    @State private var photoItem: PhotosPickerItem?
    @State private var candidates: [String] = []
    @State private var scanning = false
    @State private var scanMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("名称，如 iPhone 15", text: $name)
                    TextField("品牌", text: $brand)
                }

                Section {
                    TextField("序列号", text: $serial)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("从照片识别", systemImage: "text.viewfinder")
                    }

                    if scanning {
                        ProgressView("识别中…")
                    }

                    if let scanMessage {
                        Text(scanMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !candidates.isEmpty {
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
                    }
                } header: {
                    Text("序列号")
                } footer: {
                    Text("挑一张印有序列号的标签照片。文字识别在本机完成，照片不会上传。")
                }

                Section("保修") {
                    DatePicker("购买日期", selection: $purchaseDate, displayedComponents: .date)
                    Stepper(value: $warrantyMonths, in: 0...60) {
                        Text("保修 \(warrantyMonths) 个月")
                    }
                }

                Section("备注") {
                    TextField("可选", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("添加设备")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: photoItem) { _, newValue in
                guard let newValue else { return }
                Task { await scan(newValue) }
            }
        }
    }

    private func scan(_ pick: PhotosPickerItem) async {
        scanning = true
        scanMessage = nil
        defer { scanning = false }

        guard let data = try? await pick.loadTransferable(type: Data.self) else {
            scanMessage = "读不到这张照片，换一张试试。"
            return
        }

        let found = await SerialScanner.candidates(from: data)
        candidates = found

        if let best = found.first {
            serial = best
        } else {
            scanMessage = "没找到像序列号的文字，手动输入吧。"
        }
    }

    private func save() {
        let item = GearItem(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces),
            serial: serial.trimmingCharacters(in: .whitespaces),
            purchaseDate: purchaseDate,
            warrantyMonths: warrantyMonths,
            notes: notes
        )
        context.insert(item)
        try? context.save()

        // Ask only once the user has something worth reminding them about.
        Task {
            _ = await Reminders.requestAuthorization()
            await Reminders.reschedule(for: item)
        }
        dismiss()
    }
}
