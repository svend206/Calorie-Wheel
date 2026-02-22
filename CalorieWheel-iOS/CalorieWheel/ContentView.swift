import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var dataStore = CalorieDataStore.shared
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: 0x1A1A1A)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: Daily Goal label + Settings button
                HStack {
                    Spacer()

                    VStack(spacing: 2) {
                        Text("Daily Goal")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: 0xB0B0B0))
                        Text("\(dataStore.dailyGoal) cal")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(Color(hex: 0xB0B0B0))
                            .frame(width: 48, height: 48)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 8)

                Spacer()

                // The Calorie Wheel
                CalorieWheelView(
                    dataStore: dataStore,
                    onCalorieChanged: { _ in
                        // Update widget when calories change
                        WidgetCenter.shared.reloadAllTimelines()
                    },
                    onLongPress: {
                        showSettings = true
                    }
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 32)

                Spacer()

                // Hint text
                Text("Long press wheel for settings")
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0xB0B0B0))
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView(dataStore: dataStore)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check for 3am reset when app comes to foreground
            dataStore.checkAndResetIfNewDay()
        }
    }
}
