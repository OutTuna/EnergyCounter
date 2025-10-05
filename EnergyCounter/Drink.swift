import Foundation
import SwiftData

@Model
class Drink {
    var date: Date
    var name: String
    var volume: Double
    var caffeineMG: Int

    init(date: Date, name: String, volume: Double, caffeineMG: Int) {
        self.date = date
        self.name = name
        self.volume = volume
        self.caffeineMG = caffeineMG
    }
}
