import Foundation

enum EnergyDrinkSuggestions {
    static func load() -> [EnergyDrink] {
        guard let url = Bundle.main.url(forResource: "energy_drinks", withExtension: "json") else {
            print("❌ Файл не найден")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([EnergyDrink].self, from: data)
        } catch {
            print("❌ Ошибка загрузки JSON: \(error)")
            return []
        }
    }
}
