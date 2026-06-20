import SwiftUI
import AuthenticationServices

/// First launch. The breathing circle is already alive behind a single Sign-in-with-Apple
/// button, so the value reads in under 3 seconds with zero typing.
struct OnboardingView: View {
    @EnvironmentObject var account: AccountManager
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = false

    var body: some View {
        ZStack {
            EaseBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                BreathingCircle(scale: pulse ? 0.9 : 0.58)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulse)

                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Text("Ease")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Calm in one minute.\nJust follow the circle.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    SignInWithAppleButton(.continue) { request in
                        account.configure(request)
                    } onCompletion: { result in
                        account.handle(result)
                    }
                    .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(Capsule())

                    Text("No subscription. No ads. Your breathing stays private.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)
            }
            .padding()
        }
        .onAppear { pulse = true }
    }
}
