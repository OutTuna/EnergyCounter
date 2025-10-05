import SwiftUI
import SwiftData

enum AppPage: Hashable {
    case friends
    case home
    case menu
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Drink.date, order: .reverse) private var drinks: [Drink]

    @State private var drinkName = ""
    @State private var volumeText = ""
    @State private var selectedDay = Date()
    @State private var availableDrinks: [EnergyDrink] = EnergyDrinkSuggestions.load()
    @State private var selectedDrink: EnergyDrink? = nil

    @State private var currentPage: AppPage = .home

    var body: some View {
        NavigationView {
            TabView(selection: $currentPage) {
                // Друзья
                comingSoonView(title: "Друзья")
                    .tag(AppPage.friends)

                // Главная (дом)
                homeView
                    .tag(AppPage.home)

                // Меню / Настройки
                comingSoonView(title: "Меню")
                    .tag(AppPage.menu)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle("EnergyCounter")
            .toolbar {
                // Верхний тулбар показываем только на главной
                if currentPage == .home {
                    // Кнопка "Вчера"
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(previousDayLabel()) {
                            if let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) {
                                selectedDay = prev
                            }
                        }
                    }

                    // 🔥 Огонёк + счётчик — по центру
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Text("🔥")
                                .font(.title2)
                                .opacity(caffeineForDay(selectedDay) > 0 ? 1 : 0.3)

                            Text("\(currentStreakDays()) дн.")
                                .font(.footnote)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }

                    // Кнопка "Завтра"
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(nextDayLabel()) {
                            if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) {
                                selectedDay = next
                            }
                        }
                    }
                } else {
                    // Для страниц-заглушек оставим нейтральный центр
                    ToolbarItem(placement: .principal) {
                        Text("")
                    }
                }

                // Нижний бар (всегда)
                ToolbarItemGroup(placement: .bottomBar) {
                    // Друзья (слева)
                    Button {
                        withAnimation(.easeInOut) {
                            currentPage = .friends
                        }
                    } label: {
                        VStack {
                            Image(systemName: "person.2.fill")
                            Text("Друзья")
                        }
                    }

                    Spacer()

                    // Главная (по центру)
                    Button {
                        withAnimation(.easeInOut) {
                            currentPage = .home
                        }
                    } label: {
                        VStack {
                            Image(systemName: "house.fill")
                            Text("Главная")
                        }
                    }

                    Spacer()

                    // Меню (справа)
                    Button {
                        withAnimation(.easeInOut) {
                            currentPage = .menu
                        }
                    } label: {
                        VStack {
                            Image(systemName: "line.3.horizontal")
                            Text("Меню")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Home page

    private var homeView: some View {
        VStack(spacing: 12) {
            Text("Кофеин за \(dayLabel(for: selectedDay)): \(caffeineForDay(selectedDay)) мг")
                .font(.headline)

            // Поле для ввода названия
            TextField("Название энергетика", text: $drinkName)
                .textFieldStyle(.roundedBorder)

            // Подсказки
            if !drinkName.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(availableDrinks.filter {
                            $0.name.lowercased().contains(drinkName.lowercased())
                        }) { drink in
                            Button {
                                drinkName = drink.name
                                selectedDrink = drink
                            } label: {
                                HStack {
                                    Text(drink.name)
                                    Spacer()
                                    Text("\(drink.caffeinePer100ml) мг/100мл")
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 120)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            // Объём
            TextField("Объём (л)", text: $volumeText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            Button("Добавить") { addDrink(for: selectedDay) }
                .buttonStyle(.borderedProminent)
                .disabled(drinkName.isEmpty || volumeText.isEmpty)

            Divider()

            // История
            List {
                if drinksForDay(selectedDay).isEmpty {
                    Text("Пока ничего не добавлено").foregroundColor(.gray)
                } else {
                    ForEach(drinksForDay(selectedDay), id: \.persistentModelID) { drink in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(drink.name).font(.headline)
                                Text("\(drink.volume, specifier: "%.2f") л")
                                    .font(.subheadline).foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(drink.caffeineMG) мг").bold()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteDrink(drink)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Placeholder pages

    private func comingSoonView(title: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: title == "Меню" ? "line.3.horizontal" : "person.2.fill")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("This Page will be coming soon...")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - Logic

    private func addDrink(for day: Date) {
        guard let volume = Double(volumeText) else { return }
        let caffeinePer100ml = selectedDrink?.caffeinePer100ml ?? 30
        let caffeine = Int(volume * 1000 / 100 * Double(caffeinePer100ml))

        let newDrink = Drink(date: day, name: drinkName, volume: volume, caffeineMG: caffeine)
        context.insert(newDrink)
        try? context.save()

        drinkName = ""
        volumeText = ""
        selectedDrink = nil
    }

    private func deleteDrink(_ drink: Drink) {
        context.delete(drink)
        try? context.save()
    }

    private func drinksForDay(_ day: Date) -> [Drink] {
        let cal = Calendar.current
        return drinks.filter { cal.isDate($0.date, inSameDayAs: day) }
    }

    private func caffeineForDay(_ day: Date) -> Int {
        drinksForDay(day).map { $0.caffeineMG }.reduce(0, +)
    }

    private func currentStreakDays() -> Int {
        let cal = Calendar.current
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        while true {
            if !drinksForDay(cursor).isEmpty {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = cal.startOfDay(for: prev)
            } else {
                break
            }
        }
        return streak
    }

    private func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "сегодня" }
        if cal.isDateInYesterday(date) { return "вчера" }
        if cal.isDateInTomorrow(date) { return "завтра" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }

    private func previousDayLabel() -> String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDay) { return "Вчера" }
        else if cal.isDateInTomorrow(selectedDay) { return "Сегодня" }
        else { return "◀︎" }
    }

    private func nextDayLabel() -> String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDay) { return "Завтра" }
        else if cal.isDateInYesterday(selectedDay) { return "Сегодня" }
        else { return "▶︎" }
    }
}
