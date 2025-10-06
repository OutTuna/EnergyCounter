import SwiftUI
import SwiftData

@main
struct EnergyCounterApp: App {
    @AppStorage("restartKey") var restartKey = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(restartKey)
                .modelContainer(for: Drink.self)
        }
    }
}
