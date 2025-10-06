import SwiftData
import Foundation

@Model
class Drink: Identifiable {
    var id: UUID
    var date: Date
    var name: String
    var volume: Double
    var caffeineMG: Int

    init(date: Date, name: String, volume: Double, caffeineMG: Int) {
        self.id = UUID()
        self.date = date
        self.name = name
        self.volume = volume
        self.caffeineMG = caffeineMG
    }
}

