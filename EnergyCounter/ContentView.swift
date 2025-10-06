import SwiftUI
import SwiftData

enum AppPage: Hashable {
    case friends, home, settings
}

struct ContentView: View {
    // MARK: - SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \Drink.date, order: .reverse) private var drinks: [Drink]

    // MARK: - AppStorage
    @AppStorage("selectedTheme") private var selectedTheme: Int = 0
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("restartKey") private var restartKey = false

    // MARK: - State
    @State private var currentPage: AppPage = .home
    @State private var drinkName: String = ""
    @State private var volumeText: String = ""
    @State private var selectedDrink: EnergyDrink? = nil
    @State private var selectedDay: Date = Date()
    @State private var showStreakPopup = false
    @State private var availableDrinks: [EnergyDrink] = EnergyDrinkSuggestions.load()

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    switch currentPage {
                    case .home: homeView
                    case .friends: comingSoonView(title: NSLocalizedString("friends", comment: ""))
                    case .settings: settingsView
                    }
                    Spacer()
                    bottomBar
                }
                .toolbar {
                    if currentPage == .home {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(previousDayLabel()) {
                                if let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) {
                                    selectedDay = prev
                                }
                            }
                        }
                        ToolbarItem(placement: .principal) {
                            Button {
                                withAnimation { showStreakPopup = true }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("🔥")
                                        .font(.title2)
                                        .opacity(caffeineForDay(selectedDay) > 0 ? 1 : 0.3)
                                    Text("\(currentStreakDays()) \(NSLocalizedString("days", comment: ""))")
                                        .font(.footnote)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(nextDayLabel()) {
                                if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) {
                                    selectedDay = next
                                }
                            }
                        }
                    }
                }
            }
            .blur(radius: showStreakPopup ? 6 : 0) // <-- теперь размывается и тулбар тоже

            if showStreakPopup {
                streakPopup
            }
        }
        .preferredColorScheme(resolveColorScheme())
        .onChange(of: selectedLanguage) { newLang in
            Bundle.setLanguage(newLang)
            restartKey.toggle()
        }
    }



    // MARK: - Home
    private var homeView: some View {
        VStack(spacing: 16) {
            Text(String(format: NSLocalizedString("caffeine_for_day", comment: ""),
                        dayLabel(for: selectedDay),
                        caffeineForDay(selectedDay)))
                .font(.headline)

            // Поле для названия напитка
            TextField(NSLocalizedString("drink_name", comment: ""), text: $drinkName)
                .textFieldStyle(.roundedBorder)

            // Подсказки
            if !drinkName.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(availableDrinks.filter { $0.name.lowercased().contains(drinkName.lowercased()) }) { drink in
                            Button {
                                drinkName = drink.name
                                selectedDrink = drink
                            } label: {
                                HStack {
                                    Text(drink.name)
                                    Spacer()
                                    Text("\(drink.caffeinePer100ml) \(NSLocalizedString("mg_per_100ml", comment: ""))")
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 120)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            // Поле для объёма
            TextField(NSLocalizedString("volume_l", comment: ""), text: $volumeText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            // Кнопка добавить
            Button(NSLocalizedString("add", comment: "")) {
                addDrink(for: selectedDay)
            }
            .buttonStyle(.borderedProminent)
            .disabled(drinkName.isEmpty || volumeText.isEmpty)

            Divider()

            // История
            List {
                if drinksForDay(selectedDay).isEmpty {
                    Text(NSLocalizedString("nothing_yet", comment: ""))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(drinksForDay(selectedDay)) { drink in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(drink.name).font(.headline)
                                Text("\(drink.volume, specifier: "%.2f") L")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(drink.caffeineMG) mg")
                                .font(.subheadline)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let drink = drinksForDay(selectedDay)[index]
                            deleteDrink(drink)
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Settings
    private var settingsView: some View {
        Form {
            Section(header: Text(NSLocalizedString("theme", comment: ""))) {
                Picker("Theme", selection: $selectedTheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }
            Section(header: Text(NSLocalizedString("language", comment: ""))) {
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("en")
                    Text("Русский").tag("ru")
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            singleIconButton(systemName: "person.2.fill",
                             label: NSLocalizedString("friends", comment: ""),
                             page: .friends)
            singleIconButton(systemName: "house.fill",
                             label: NSLocalizedString("home", comment: ""),
                             page: .home)
            singleIconButton(systemName: "gearshape.fill",
                             label: NSLocalizedString("settings", comment: ""),
                             page: .settings)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
//damn.
    // MARK: - StreakPopup
    private var streakPopup: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showStreakPopup = false }
                }

            VStack(spacing: 12) {
                Text(NSLocalizedString("your_streak", comment: ""))
                    .font(.headline)
                Text("\(currentStreakDays()) \(NSLocalizedString("days", comment: ""))")
                    .font(.largeTitle)
                    .bold()
            }
            .padding()
            .frame(maxWidth: 250)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            .shadow(radius: 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // <-- центрируем строго
            .transition(.scale.combined(with: .opacity))
        }
    }


    // MARK: - Helpers
    private func resolveColorScheme() -> ColorScheme? {
        switch selectedTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    private func singleIconButton(systemName: String, label: String, page: AppPage) -> some View {
        let isSelected = currentPage == page
        return Button {
            withAnimation { currentPage = page }
        } label: {
            VStack {
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassCellPressStyle())
    }

    private func addDrink(for day: Date) {
        guard let volume = Double(volumeText.replacingOccurrences(of: ",", with: ".")) else { return }
        let caffeinePer100ml = selectedDrink?.caffeinePer100ml ?? 32
        let caffeineMG = Int(volume * 1000.0 / 100.0 * Double(caffeinePer100ml))

        let startOfDay = Calendar.current.startOfDay(for: day)

        let newDrink = Drink(date: startOfDay, name: drinkName, volume: volume, caffeineMG: caffeineMG)
        context.insert(newDrink)

        drinkName = ""
        volumeText = ""
        selectedDrink = nil
    }


    private func deleteDrink(_ drink: Drink) {
        context.delete(drink)
    }

    private func drinksForDay(_ day: Date) -> [Drink] {
        drinks.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func caffeineForDay(_ day: Date) -> Int {
        drinksForDay(day).map { $0.caffeineMG }.reduce(0, +)
    }

    private func currentStreakDays() -> Int {
        var streak = 0
        var day = Date()
        while caffeineForDay(day) > 0 {
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private func dayLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return NSLocalizedString("today", comment: "")
        } else if Calendar.current.isDateInYesterday(date) {
            return NSLocalizedString("yesterday", comment: "")
        } else if Calendar.current.isDateInTomorrow(date) {
            return NSLocalizedString("tomorrow", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: selectedLanguage)
            return formatter.string(from: date)
        }
    }

    private func previousDayLabel() -> String {
        if Calendar.current.isDateInToday(selectedDay) {
            return NSLocalizedString("yesterday", comment: "")
        } else if Calendar.current.isDateInYesterday(selectedDay) {
            return NSLocalizedString("day_before_yesterday", comment: "")
        } else if Calendar.current.isDateInTomorrow(selectedDay) {
            return NSLocalizedString("today", comment: "")
        } else {
            let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay)!
            return dayLabel(for: prev)
        }
    }

    private func nextDayLabel() -> String {
        if Calendar.current.isDateInToday(selectedDay) {
            return NSLocalizedString("tomorrow", comment: "")
        } else if Calendar.current.isDateInTomorrow(selectedDay) {
            return NSLocalizedString("day_after_tomorrow", comment: "")
        } else if Calendar.current.isDateInYesterday(selectedDay) {
            return NSLocalizedString("today", comment: "")
        } else {
            let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay)!
            return dayLabel(for: next)
        }
    }

    private func comingSoonView(title: String) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(NSLocalizedString("coming_soon", comment: ""))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Press Style
struct GlassCellPressStyle: ButtonStyle {
    var compress: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect((compress && configuration.isPressed) ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.9),
                       value: configuration.isPressed)
    }
}
