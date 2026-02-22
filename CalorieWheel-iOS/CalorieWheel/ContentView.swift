import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var dataStore = CalorieDataStore.shared
    @State private var showSettings = false
    @State private var showHistory = false

    var body: some View {
        ZStack {
            if !dataStore.hasSeenOnboarding {
                OnboardingView(dataStore: dataStore)
            } else {
                mainContent
            }
        }
    }

    private var mainContent: some View {
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

                // History button — small, subtle
                Button {
                    showHistory = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.compact.up")
                            .font(.caption)
                        Text("History")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: 0x666666))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView(dataStore: dataStore)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(dataStore: dataStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    // Swipe up to show history
                    if value.translation.height < -50 && abs(value.translation.width) < abs(value.translation.height) {
                        showHistory = true
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check for 3am reset when app comes to foreground
            dataStore.checkAndResetIfNewDay()
        }
    }
}
