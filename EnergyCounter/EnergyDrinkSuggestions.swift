import Foundation

struct EnergyDrinkSuggestions {
    static func load() -> [EnergyDrink] {
        guard let url = Bundle.main.url(forResource: "drinks", withExtension: "json") else {
            print("⚠️ drinks.json не найден")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let drinks = try JSONDecoder().decode([EnergyDrink].self, from: data)
            return drinks
        } catch {
            print("❌ Ошибка загрузки JSON: \(error)")
            return []
        }
    }
}
