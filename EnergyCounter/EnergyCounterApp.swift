import SwiftUI
import SwiftData

@main
struct EnergyCounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Drink.self)
    }
}
