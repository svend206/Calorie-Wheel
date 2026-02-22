import SwiftUI

@main
struct CalorieWheelApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Check for day boundary reset every time the app becomes active
                CalorieDataStore.shared.checkAndResetIfNewDay()
            }
        }
    }
}
