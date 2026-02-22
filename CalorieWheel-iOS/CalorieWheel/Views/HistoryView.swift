import SwiftUI

struct HistoryView: View {
    @ObservedObject var dataStore: CalorieDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: 0x1A1A1A)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                // Weekly chart
                WeeklyChartView(dataStore: dataStore)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                // History list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(dataStore.loadHistory()) { record in
                            HistoryRow(record: record)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let record: DailyRecord

    private var dateText: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(record.date) {
            return "Today"
        } else if calendar.isDateInYesterday(record.date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: record.date)
        }
    }

    private var color: Color {
        let pct = record.percentage
        if pct < 0.5 {
            return Color(hex: 0x4CAF50)
        } else if pct < 0.75 {
            return Color(hex: 0xFF9800)
        } else {
            return Color(hex: 0xF44336)
        }
    }

    var body: some View {
        HStack {
            Text(dateText)
                .font(.body)
                .foregroundStyle(Color(hex: 0xB0B0B0))

            Spacer()

            Text("\(record.calories)")
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(color)

            Text("cal")
                .font(.caption)
                .foregroundStyle(Color(hex: 0x666666))
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Weekly Bar Chart

struct WeeklyChartView: View {
    @ObservedObject var dataStore: CalorieDataStore

    private var records: [DailyRecord] {
        dataStore.loadRecentHistory(days: 7)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let full = formatter.string(from: date)
        return String(full.prefix(1)).uppercased()
    }

    private func barColor(for record: DailyRecord) -> Color {
        let pct = record.percentage
        if pct < 0.5 {
            return Color(hex: 0x4CAF50)
        } else if pct < 0.75 {
            return Color(hex: 0xFF9800)
        } else {
            return Color(hex: 0xF44336)
        }
    }

    var body: some View {
        let maxValue = max(CGFloat(dataStore.dailyGoal), CGFloat(records.map(\.calories).max() ?? 0))

        VStack(spacing: 8) {
            // Bar chart
            GeometryReader { geo in
                let barSpacing: CGFloat = 8
                let totalSpacing = barSpacing * CGFloat(records.count - 1)
                let barWidth = max((geo.size.width - totalSpacing) / CGFloat(max(records.count, 1)), 4)
                let chartHeight = geo.size.height

                ZStack(alignment: .bottom) {
                    // Goal line
                    let goalY = maxValue > 0
                        ? chartHeight * (1 - CGFloat(dataStore.dailyGoal) / maxValue)
                        : chartHeight

                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .offset(y: -chartHeight + goalY)

                    // Bars
                    HStack(alignment: .bottom, spacing: barSpacing) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { _, record in
                            let barHeight = maxValue > 0
                                ? max(chartHeight * CGFloat(record.calories) / maxValue, 4)
                                : 4

                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: record))
                                .frame(width: barWidth, height: barHeight)
                        }
                    }
                }
            }
            .frame(height: 100)

            // Day labels
            HStack(spacing: 8) {
                ForEach(Array(records.enumerated()), id: \.element.id) { _, record in
                    Text(dayLabel(for: record.date))
                        .font(.caption2)
                        .foregroundStyle(Color(hex: 0x666666))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
