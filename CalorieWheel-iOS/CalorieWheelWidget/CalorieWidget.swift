import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct CalorieEntry: TimelineEntry {
    let date: Date
    let currentCalories: Int
    let dailyGoal: Int
    let percentage: Int

    var color: Color {
        if percentage < 50 {
            return Color(red: 0x4C / 255.0, green: 0xAF / 255.0, blue: 0x50 / 255.0) // Green
        } else if percentage < 75 {
            return Color(red: 0xFF / 255.0, green: 0x98 / 255.0, blue: 0x00 / 255.0) // Orange
        } else {
            return Color(red: 0xF4 / 255.0, green: 0x43 / 255.0, blue: 0x36 / 255.0) // Red
        }
    }
}

// MARK: - Timeline Provider

struct CalorieTimelineProvider: TimelineProvider {
    private let appGroupID = "group.com.iotbearings.caloriewheel"

    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), currentCalories: 0, dailyGoal: 2400, percentage: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = makeEntry()
        // Update every 30 minutes (matching Android widget)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry() -> CalorieEntry {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let currentCalories = defaults.integer(forKey: "current_calories")
        let storedGoal = defaults.integer(forKey: "daily_goal")
        let dailyGoal = storedGoal > 0 ? storedGoal : 2400
        let percentage = dailyGoal > 0 ? min(currentCalories * 100 / dailyGoal, 100) : 0

        return CalorieEntry(
            date: Date(),
            currentCalories: currentCalories,
            dailyGoal: dailyGoal,
            percentage: percentage
        )
    }
}

// MARK: - Widget View

struct CalorieWidgetEntryView: View {
    var entry: CalorieEntry

    var body: some View {
        VStack(spacing: 6) {
            // Large calorie number
            Text("\(entry.currentCalories)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(entry.color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            // "cal" label
            Text("cal")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Goal text
            Text("\(entry.currentCalories) / \(entry.dailyGoal) cal")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry.color)
                        .frame(width: geo.size.width * CGFloat(entry.percentage) / 100, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .widgetBackground(Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0))
    }
}

// MARK: - Widget Configuration

struct CalorieWidget: Widget {
    let kind: String = "CalorieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieTimelineProvider()) { entry in
            CalorieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calorie Wheel")
        .description("Track your daily calorie intake with a simple rotating wheel")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - iOS 16/17 Widget Background Compatibility

extension View {
    @ViewBuilder
    func widgetBackground(_ background: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                background
            }
        } else {
            self.background(background)
        }
    }
}
