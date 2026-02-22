import SwiftUI

/// SwiftUI wrapper for the Core Graphics-based CalorieWheelUIView.
struct CalorieWheelView: UIViewRepresentable {

    @ObservedObject var dataStore: CalorieDataStore
    var onCalorieChanged: ((Int) -> Void)?
    var onLongPress: (() -> Void)?

    func makeUIView(context: Context) -> CalorieWheelUIView {
        let view = CalorieWheelUIView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: CalorieWheelUIView, context: Context) {
        uiView.refresh()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, CalorieWheelDelegate {
        let parent: CalorieWheelView

        init(_ parent: CalorieWheelView) {
            self.parent = parent
        }

        func calorieWheelDidChangeCalories(_ calories: Int) {
            parent.onCalorieChanged?(calories)
        }

        func calorieWheelDidLongPress() {
            parent.onLongPress?()
        }
    }
}
