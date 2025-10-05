import Foundation

struct EnergyDrink: Codable, Identifiable {
    let id = UUID()
    let name: String
    let caffeinePer100ml: Int
}
