import Foundation
import Combine

/// A single day's calorie record for history tracking.
struct DailyRecord: Identifiable, Codable {
    let id: String          // date key, e.g. "2026-47"
    let date: Date          // the actual calendar date
    let calories: Int
    let goal: Int

    var percentage: Float {
        guard goal > 0 else { return 0 }
        return min(max(Float(calories) / Float(goal), 0), 1)
    }
}

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
        static let history = "calorie_history"
        static let hasSeenOnboarding = "has_seen_onboarding"
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
            saveTodayToHistory()
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
            saveTodayToHistory()
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

    @Published var hasSeenOnboarding: Bool {
        didSet {
            defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)
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

        self._hasSeenOnboarding = Published(initialValue: storage.bool(forKey: Keys.hasSeenOnboarding))

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
            // Save yesterday's final tally before resetting
            saveHistoryRecord(dateKey: lastDate, calories: currentCalories, goal: dailyGoal)
            currentCalories = 0
            defaults.set(currentKey, forKey: Keys.lastUpdateDate)
        } else if lastUpdateDate == nil {
            defaults.set(currentKey, forKey: Keys.lastUpdateDate)
        }
    }

    /// Get a date key that changes at 3am instead of midnight.
    func currentDateKey() -> String {
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

    // MARK: - History

    /// Save today's current state to history.
    private func saveTodayToHistory() {
        let key = currentDateKey()
        saveHistoryRecord(dateKey: key, calories: currentCalories, goal: dailyGoal)
    }

    /// Save a history record for a given date key.
    private func saveHistoryRecord(dateKey: String, calories: Int, goal: Int) {
        var history = loadHistoryDict()
        history[dateKey] = ["calories": calories, "goal": goal]

        // Keep only the last 90 days
        if history.count > 90 {
            let sorted = history.keys.sorted()
            let toRemove = sorted.prefix(history.count - 90)
            for key in toRemove {
                history.removeValue(forKey: key)
            }
        }

        defaults.set(history, forKey: Keys.history)
    }

    /// Load raw history dictionary from UserDefaults.
    private func loadHistoryDict() -> [String: [String: Int]] {
        defaults.dictionary(forKey: Keys.history) as? [String: [String: Int]] ?? [:]
    }

    /// Load history as sorted DailyRecord array (most recent first).
    func loadHistory() -> [DailyRecord] {
        let history = loadHistoryDict()
        let calendar = Calendar.current

        return history.compactMap { key, value in
            guard let calories = value["calories"],
                  let goal = value["goal"] else { return nil }

            // Parse "YYYY-DDD" format back to a Date
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let year = Int(parts[0]),
                  let dayOfYear = Int(parts[1]) else { return nil }

            var comps = DateComponents()
            comps.year = year
            comps.day = dayOfYear
            let date = calendar.date(from: comps) ?? Date()

            return DailyRecord(id: key, date: date, calories: calories, goal: goal)
        }
        .sorted { $0.date > $1.date }
    }

    /// Load the last N days of history for the bar chart (oldest first).
    func loadRecentHistory(days: Int) -> [DailyRecord] {
        let all = loadHistory()
        let todayKey = currentDateKey()

        // Build the recent list including today
        var recent = Array(all.prefix(days - 1))

        // Add today as the first entry if not already present
        if recent.first?.id != todayKey {
            let todayRecord = DailyRecord(
                id: todayKey,
                date: Date(),
                calories: currentCalories,
                goal: dailyGoal
            )
            recent.insert(todayRecord, at: 0)
            if recent.count > days {
                recent = Array(recent.prefix(days))
            }
        }

        return recent.reversed() // oldest first for chart
    }
}
