import SwiftUI

struct MenuView: View {
    @AppStorage("selectedTheme") private var selectedTheme: Int = 0

    var body: some View {
        Form {
            Section(header: Text("Settings")) {
                Picker("Тема", selection: $selectedTheme) {
                    Text("System").tag(0)
                    Text("Bright").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Text("This Page will be coming soon...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Menu")
    }
}
