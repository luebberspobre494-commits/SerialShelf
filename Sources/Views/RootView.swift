import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            ItemsView()
                .tabItem { Label("Items", systemImage: "shippingbox.fill") }

            WarrantyView()
                .tabItem { Label("Warranty", systemImage: "shield.lefthalf.filled") }

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: GearItem.self, inMemory: true)
}
