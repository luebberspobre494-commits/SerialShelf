import SwiftUI
import UIKit

/// A card that can be shared as an image: the thing you send to a buyer on
/// Marketplace, or hand to a repair desk, instead of a screenshot of a list.
struct WarrantyCard: View {
    let item: GearItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: item.itemCategory.symbol)
                    .font(.system(size: 34, weight: .semibold))
                Spacer()
                Text("SerialShelf")
                    .font(.system(size: 22, weight: .semibold))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)

            Spacer(minLength: 24)

            Text(item.name)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            if !item.brand.isEmpty {
                Text(item.brand)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 12) {
                row("Serial", item.serial.isEmpty ? "not recorded" : item.serial, mono: true)
                row("Purchased", item.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                row("Warranty ends", item.warrantyEnd.formatted(date: .abbreviated, time: .omitted))
                row("Status", item.statusText)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.14))
            )

            Spacer(minLength: 18)

            Text("Verified on device with SerialShelf")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(44)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func row(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 170, alignment: .leading)
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: mono ? .monospaced : .default))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer(minLength: 0)
        }
    }

    private var gradient: [Color] {
        switch item.warrantyState {
        case .active:
            return [Color(red: 0.09, green: 0.20, blue: 0.42), Color(red: 0.13, green: 0.42, blue: 0.72)]
        case .endingSoon:
            return [Color(red: 0.42, green: 0.22, blue: 0.06), Color(red: 0.82, green: 0.48, blue: 0.12)]
        case .expired:
            return [Color(red: 0.28, green: 0.10, blue: 0.12), Color(red: 0.60, green: 0.20, blue: 0.24)]
        }
    }
}

enum WarrantyCardRenderer {
    @MainActor
    static func image(for item: GearItem) -> UIImage? {
        let renderer = ImageRenderer(
            content: WarrantyCard(item: item)
                .frame(width: 900, height: 1200)
        )
        renderer.scale = 2
        return renderer.uiImage
    }
}
