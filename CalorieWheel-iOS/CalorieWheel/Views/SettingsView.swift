import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataStore: CalorieDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var showGoalInput = false
    @State private var goalInputText = ""
    @State private var showResetConfirm = false

    private let incrementOptions = [10, 25, 50, 100]

    var body: some View {
        NavigationStack {
            List {
                // Daily Goal
                Section {
                    Button {
                        goalInputText = "\(dataStore.dailyGoal)"
                        showGoalInput = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Calorie Goal")
                                    .foregroundStyle(.white)
                                Text("\(dataStore.dailyGoal) calories")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // Increment
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wheel Increment")
                            .foregroundStyle(.white)
                        Text("\(dataStore.increment) calories per notch")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Increment", selection: $dataStore.increment) {
                            ForEach(incrementOptions, id: \.self) { value in
                                Text("\(value) cal").tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Reset
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reset Calories")
                                    .foregroundStyle(.red)
                                Text("Reset today's calories to 0")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: 0x1A1A1A))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Daily Calorie Goal", isPresented: $showGoalInput) {
                TextField("500 – 10,000", text: $goalInputText)
                    .keyboardType(.numberPad)
                Button("Save") {
                    if let value = Int(goalInputText), (500...10000).contains(value) {
                        dataStore.dailyGoal = value
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a value between 500 and 10,000")
            }
            .alert("Reset Calories", isPresented: $showResetConfirm) {
                Button("Yes", role: .destructive) {
                    dataStore.resetCalories()
                }
                Button("No", role: .cancel) {}
            } message: {
                Text("Reset calories to 0?")
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Color Hex Extension for SwiftUI

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
