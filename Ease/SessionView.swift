import SwiftUI
import UIKit
import WidgetKit

/// The live breathing session. Owns the engine, starts it on appear, and shows the Complete
/// screen when it finishes naturally. Tapping End stops early without logging a session.
struct SessionView: View {
    let pattern: BreathPattern
    let seconds: Int

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ease.haptics") private var hapticsEnabled = true
    @StateObject private var engine = SessionEngine()

    var body: some View {
        ZStack {
            EaseBackground()

            if engine.isComplete {
                CompleteView(pattern: pattern, seconds: seconds) { dismiss() }
                    .transition(.opacity)
            } else {
                sessionBody.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: engine.isComplete)
        .onChange(of: engine.phase) { _, p in
            // Speak each phase for VoiceOver users who can't see the circle.
            if p != .idle && p != .done {
                UIAccessibility.post(notification: .announcement, argument: p.label)
            }
        }
        .onAppear {
            engine.hapticsEnabled = hapticsEnabled
            engine.onComplete = { p, s in
                appModel.recordCompletion(pattern: p, seconds: s)
                WidgetCenter.shared.reloadAllTimelines()
            }
            engine.start(pattern: pattern, totalSeconds: seconds)
        }
        .onDisappear { engine.cancel(reset: true) }
    }

    private var sessionBody: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { Haptics.tap(); engine.cancel(reset: true); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(Color.easeCard, in: Circle())
                }
                .accessibilityIdentifier("endSession")
                .accessibilityLabel("End session")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            BreathingCircle(scale: engine.scale)
                .accessibilityElement()
                .accessibilityLabel("Breathing guide")
                .accessibilityValue(engine.phase.label)

            Spacer()

            VStack(spacing: 10) {
                Text(engine.phase.label)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: engine.phase)
                Text(mmss(engine.secondsRemaining))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(pattern.name + " · " + pattern.detail)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 60)
        }
    }
}
