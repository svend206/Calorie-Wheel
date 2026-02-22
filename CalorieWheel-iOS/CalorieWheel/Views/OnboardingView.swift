import SwiftUI

struct OnboardingView: View {
    @ObservedObject var dataStore: CalorieDataStore
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color(hex: 0x1A1A1A)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Pages
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "gearshape.fill",
                        iconColor: Color(hex: 0x4CAF50),
                        title: "Set your daily goal",
                        subtitle: "Tap the gear icon to choose\na calorie target that works for you"
                    )
                    .tag(0)

                    OnboardingPage(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: Color(hex: 0x8BC34A),
                        title: "Spin to log",
                        subtitle: "Drag the wheel to add calories\nas you eat throughout the day"
                    )
                    .tag(1)

                    OnboardingPage(
                        icon: "circle.lefthalf.filled",
                        iconColor: Color(hex: 0xFF9800),
                        title: "Stay on track",
                        subtitle: "The wheel shifts from green to red\nas you approach your daily goal"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Spacer()

                // Get Started button (only on last page)
                Button {
                    dataStore.hasSeenOnboarding = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: 0x4CAF50))
                        )
                }
                .opacity(currentPage == 2 ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: currentPage)
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Onboarding Page

private struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(Color(hex: 0xB0B0B0))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 40)
    }
}
