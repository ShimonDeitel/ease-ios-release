import SwiftUI

enum BreathPhase: String {
    case idle, inhale, holdIn, exhale, holdOut, done
    var label: String {
        switch self {
        case .inhale: return "Breathe in"
        case .holdIn, .holdOut: return "Hold"
        case .exhale: return "Breathe out"
        case .idle: return "Ready"
        case .done: return "Done"
        }
    }
}

/// Drives a guided breathing session: advances the phases on a cancellable async loop and
/// publishes the circle's target scale so the view animates it. Source of truth for timing.
@MainActor
final class SessionEngine: ObservableObject {
    @Published private(set) var phase: BreathPhase = .idle
    @Published private(set) var scale: CGFloat = 0.45
    @Published private(set) var phaseDuration: Double = 0
    @Published private(set) var secondsRemaining: Int = 60
    @Published private(set) var isRunning = false
    @Published private(set) var isComplete = false

    let minScale: CGFloat = 0.45
    let maxScale: CGFloat = 1.0

    var hapticsEnabled = true
    /// Called once when a session finishes naturally (not when the user stops early).
    var onComplete: ((BreathPattern, Int) -> Void)?

    private(set) var pattern: BreathPattern = .box
    private(set) var totalSeconds: Int = 60
    private var task: Task<Void, Never>?

    /// DEBUG/UI-test only — collapses a session to ~1.5s so the complete flow is testable. Off in Release.
    private var fastMode: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["EASE_FAST"] == "1"
        #else
        return false
        #endif
    }

    func start(pattern: BreathPattern, totalSeconds: Int) {
        cancel(reset: false)
        self.pattern = pattern
        self.totalSeconds = totalSeconds
        self.secondsRemaining = totalSeconds
        self.isComplete = false
        self.isRunning = true
        self.scale = minScale
        task = Task { [weak self] in await self?.run() }
    }

    /// Stop early (user tapped to end). Does NOT fire onComplete.
    func cancel(reset: Bool) {
        task?.cancel(); task = nil
        isRunning = false
        if reset {
            phase = .idle
            scale = minScale
            phaseDuration = 0
            secondsRemaining = totalSeconds
            isComplete = false
        }
    }

    private func run() async {
        // Safety floor: a zero-length pattern would never suspend (main-thread wedge). Finish cleanly.
        guard pattern.cycleSeconds > 0 else { finish(); return }
        let speedUp = fastMode
        let totalTenths = speedUp ? 14 : max(1, totalSeconds * 10)
        var elapsedTenths = 0
        func dur(_ d: Double) -> Double { d <= 0 ? 0 : (speedUp ? 0.35 : d) }

        // Run one phase: animate the circle to `target` over `dur`, sleeping in 0.1s ticks so
        // cancellation is honored and the countdown updates smoothly.
        func runPhase(_ p: BreathPhase, _ dur: Double, target: CGFloat) async -> Bool {
            guard dur > 0 else { return true }
            if hapticsEnabled { Haptics.phase(p) }
            phaseDuration = dur
            phase = p
            withAnimation(.easeInOut(duration: dur)) { scale = target }
            let ticks = max(1, Int((dur * 10).rounded()))
            for _ in 0..<ticks {
                if Task.isCancelled { return false }
                try? await Task.sleep(for: .seconds(0.1))
                if Task.isCancelled { return false }   // honor an End tap that lands during the sleep
                elapsedTenths += 1
                secondsRemaining = max(0, (totalTenths - elapsedTenths + 9) / 10)
            }
            return !Task.isCancelled
        }

        while !Task.isCancelled {
            if !(await runPhase(.inhale, dur(pattern.inhale), target: maxScale)) { return }
            if !(await runPhase(.holdIn, dur(pattern.holdIn), target: maxScale)) { return }
            if !(await runPhase(.exhale, dur(pattern.exhale), target: minScale)) { return }
            // End only on a relaxed boundary (after exhale / after the empty hold).
            if elapsedTenths >= totalTenths { break }
            if !(await runPhase(.holdOut, dur(pattern.holdOut), target: minScale)) { return }
            if elapsedTenths >= totalTenths { break }
        }

        guard !Task.isCancelled else { return }
        finish()
    }

    private func finish() {
        phase = .done
        scale = minScale
        secondsRemaining = 0
        isRunning = false
        isComplete = true
        if hapticsEnabled { Haptics.success() }
        onComplete?(pattern, totalSeconds)
    }
}
