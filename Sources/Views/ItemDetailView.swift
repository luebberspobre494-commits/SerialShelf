import SwiftUI
import SwiftData
import UIKit

struct ItemDetailView: View {
    @Bindable var item: GearItem

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirm = false

    var body: some View {
        Form {
            Section("基本") {
                TextField("名称", text: $item.name)
                TextField("品牌", text: $item.brand)
            }

            Section {
                TextField("序列号", text: $item.serial)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())

                if !item.serial.isEmpty {
                    Button {
                        UIPasteboard.general.string = item.serial
                    } label: {
                        Label("复制序列号", systemImage: "doc.on.doc")
                    }
                }
            } header: {
                Text("序列号")
            }

            Section("保修") {
                DatePicker("购买日期", selection: $item.purchaseDate, displayedComponents: .date)
                Stepper(value: $item.warrantyMonths, in: 0...60) {
                    Text("保修 \(item.warrantyMonths) 个月")
                }
                LabeledContent("到期日") {
                    Text(item.warrantyEnd, format: .dateTime.year().month().day())
                }
                LabeledContent("状态") {
                    Text(statusText)
                        .foregroundStyle(tint)
                }
            }

            Section("备注") {
                TextField("可选", text: $item.notes, axis: .vertical)
                    .lineLimit(2...6)
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("删除这台设备", systemImage: "trash")
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: item.warrantyEnd) { _, _ in
            Task { await Reminders.reschedule(for: item) }
        }
        .confirmationDialog("删除后无法恢复", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                Reminders.remove(for: item)
                context.delete(item)
                try? context.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
    }

    private var statusText: String {
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
