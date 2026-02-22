import Foundation
import Combine

/// Handles all calorie data storage and retrieval using UserDefaults.
/// Uses App Group for sharing data with the widget extension.
final class CalorieDataStore: ObservableObject {

    static let appGroupID = "group.com.iotbearings.caloriewheel"

    static let shared = CalorieDataStore()

    private let defaults: UserDefaults

    private enum Keys {
        static let currentCalories = "current_calories"
        static let dailyGoal = "daily_goal"
        static let lastUpdateDate = "last_update_date"
        static let increment = "calorie_increment"
    }

    static let defaultDailyGoal = 2400
    static let defaultIncrement = 50

    @Published var currentCalories: Int {
        didSet {
            let clamped = min(max(currentCalories, 0), dailyGoal)
            if clamped != currentCalories {
                currentCalories = clamped
                return
            }
            defaults.set(clamped, forKey: Keys.currentCalories)
            defaults.set(currentDateKey(), forKey: Keys.lastUpdateDate)
        }
    }

    @Published var dailyGoal: Int {
        didSet {
            let clamped = min(max(dailyGoal, 500), 10000)
            if clamped != dailyGoal {
                dailyGoal = clamped
                return
            }
            defaults.set(clamped, forKey: Keys.dailyGoal)
            if currentCalories > clamped {
                currentCalories = clamped
            }
        }
    }

    @Published var increment: Int {
        didSet {
            let clamped = min(max(increment, 10), 100)
            if clamped != increment {
                increment = clamped
                return
            }
            defaults.set(clamped, forKey: Keys.increment)
        }
    }

    init() {
        // Use App Group UserDefaults so the widget can access the same data
        let storage: UserDefaults
        if let groupDefaults = UserDefaults(suiteName: CalorieDataStore.appGroupID) {
            storage = groupDefaults
        } else {
            storage = UserDefaults.standard
        }
        self.defaults = storage

        // Load stored values — must initialize all stored properties before using self
        let storedGoal = storage.integer(forKey: Keys.dailyGoal)
        let goal = storedGoal > 0 ? min(max(storedGoal, 500), 10000) : CalorieDataStore.defaultDailyGoal
        self._dailyGoal = Published(initialValue: goal)

        let storedIncrement = storage.integer(forKey: Keys.increment)
        let inc = storedIncrement > 0 ? min(max(storedIncrement, 10), 100) : CalorieDataStore.defaultIncrement
        self._increment = Published(initialValue: inc)

        let storedCalories = storage.integer(forKey: Keys.currentCalories)
        self._currentCalories = Published(initialValue: min(max(storedCalories, 0), goal))

        // Check for day boundary reset
        checkAndResetIfNewDay()
    }

    /// Reset calories to 0.
    func resetCalories() {
        currentCalories = 0
        defaults.set(currentDateKey(), forKey: Keys.lastUpdateDate)
    }

    /// Check if we've passed 3am since last update and reset if so.
    func checkAndResetIfNewDay() {
        let lastUpdateDate = defaults.string(forKey: Keys.lastUpdateDate)
        let currentKey = currentDateKey()

        if let lastDate = lastUpdateDate, lastDate != currentKey {
            currentCalories = 0
            defaults.set(currentKey, forKey: Keys.lastUpdateDate)
        } else if lastUpdateDate == nil {
            defaults.set(currentKey, forKey: Keys.lastUpdateDate)
        }
    }

    /// Get a date key that changes at 3am instead of midnight.
    private func currentDateKey() -> String {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        // Subtract 3 hours so the "day" starts at 3am
        let adjusted = calendar.date(byAdding: .hour, value: -3, to: Date()) ?? Date()
        let year = calendar.component(.year, from: adjusted)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: adjusted) ?? 1
        return "\(year)-\(dayOfYear)"
    }

    /// Number of notches on the wheel based on goal and increment.
    var notchCount: Int {
        dailyGoal / increment
    }

    /// Snap a calorie value to the nearest increment.
    func snapToIncrement(_ calories: Int) -> Int {
        ((calories + increment / 2) / increment) * increment
    }

    /// Percentage of daily goal consumed (0.0 to 1.0).
    var percentage: Float {
        guard dailyGoal > 0 else { return 0 }
        return min(max(Float(currentCalories) / Float(dailyGoal), 0), 1)
    }
}
