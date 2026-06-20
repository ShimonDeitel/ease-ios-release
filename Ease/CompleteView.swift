import SwiftUI

/// Shown right after a session finishes — the "I feel calmer" moment. Celebrates the streak,
/// offers the shareable Calm Card, and (for free users) surfaces the $0.99 upgrade once.
struct CompleteView: View {
    let pattern: BreathPattern
    let seconds: Int
    let onDone: () -> Void

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @State private var appear = false
    @State private var shareImage: UIImage?
    @State private var showShare = false
    @State private var showPaywall = false

    private var streakLine: String {
        let s = appModel.currentStreak
        if s <= 1 { return "Your first breath today" }
        return "\(s) days in a row"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .background(Color.easeAccent, in: Circle())
                .scaleEffect(appear ? 1 : 0.6)
                .opacity(appear ? 1 : 0)

            VStack(spacing: 8) {
                Text("Nice.").font(.system(size: 34, weight: .bold, design: .rounded))
                Text(streakLine).font(.title3).foregroundStyle(.secondary)
                Text("\(appModel.totalMinutes) min of calm so far")
                    .font(.subheadline).foregroundStyle(.tertiary).padding(.top, 2)
            }
            .padding(.top, 22)
            .opacity(appear ? 1 : 0)

            Spacer()

            if !store.isPro { upgradeCard.padding(.bottom, 16) }

            VStack(spacing: 12) {
                Button { share() } label: {
                    Label("Share your calm", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .softButton()

                Button { Haptics.tap(); onDone() } label: {
                    Text("Done").frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .prominentButton()
                .accessibilityIdentifier("complete-done")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .sheet(isPresented: $showShare) {
            if let shareImage {
                ShareSheet(items: [shareImage, "Calm in one minute with Ease."])
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appear = true } }
    }

    private var upgradeCard: some View {
        Button { Haptics.tap(); showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles").font(.headline).foregroundStyle(Color.easeAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Ease Pro").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text("Custom patterns, more presets & your full history — \(store.displayPrice) once")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color.easeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func share() {
        Haptics.tap()
        let card = CalmCard(
            headline: appModel.currentStreak > 1 ? "Day \(appModel.currentStreak)" : "Just breathed",
            sub: "\(appModel.totalMinutes) min of calm",
            pattern: pattern
        )
        shareImage = card.render()
        showShare = true
    }
}
