import SwiftUI
import SwiftData

@main
struct SerialShelfApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: GearItem.self)
    }
}
