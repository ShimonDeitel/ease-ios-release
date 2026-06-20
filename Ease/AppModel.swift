import Foundation
import SwiftData
import SwiftUI

/// App state: owns the SwiftData store, derives streak/stats, persists custom patterns,
/// and exports the widget snapshot. Stats are always derived from sessions — never stored truth.
@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var currentStreak = 0
    @Published private(set) var longestStreak = 0
    @Published private(set) var totalSessions = 0
    @Published private(set) var totalMinutes = 0
    @Published private(set) var sessionsThisWeek = 0
    @Published private(set) var didBreatheToday = false
    @Published private(set) var lastPatternName = "Box"
    @Published private(set) var customPatterns: [BreathPattern] = []

    private let kCustom = "ease.custom.patterns"

    init(container: ModelContainer) {
        self.container = container
        loadCustom()
        #if DEBUG
        seedIfRequested()
        #endif
        refresh()
    }

    // MARK: Container (offline-first; CloudKit private-DB mirroring when an iCloud account exists)

    static func makeContainer() -> ModelContainer {
        let schema = Schema([BreathSession.self])
        // Only attempt CloudKit when the device actually has an iCloud account — avoids noisy
        // errors in the simulator and degrades gracefully to local-only (per spec).
        if FileManager.default.ubiquityIdentityToken != nil {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            if let c = try? ModelContainer(for: schema, configurations: cloud) { return c }
        }
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        // Last resort so the app never crashes on launch.
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    // MARK: Sessions

    func recordCompletion(pattern: BreathPattern, seconds: Int) {
        let ctx = container.mainContext
        ctx.insert(BreathSession(patternID: pattern.id, patternName: pattern.name, seconds: seconds))
        try? ctx.save()
        refresh()
    }

    func recentSessions(limit: Int = 60) -> [BreathSession] {
        var d = FetchDescriptor<BreathSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        d.fetchLimit = limit
        return (try? container.mainContext.fetch(d)) ?? []
    }

    // MARK: Stats

    func refresh() {
        let all = (try? container.mainContext.fetch(FetchDescriptor<BreathSession>())) ?? []
        totalSessions = all.count
        totalMinutes = all.reduce(0) { $0 + $1.seconds } / 60
        if let last = all.max(by: { $0.date < $1.date }) { lastPatternName = last.patternName }

        let cal = Calendar.current
        let days = Set(all.map { cal.startOfDay(for: $0.date) })
        didBreatheToday = days.contains(cal.startOfDay(for: .now))
        currentStreak = Self.currentStreak(days: days, cal: cal)
        longestStreak = Self.longestStreak(days: days, cal: cal)
        sessionsThisWeek = all.filter { cal.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.count
        exportSnapshot()
    }

    nonisolated static func currentStreak(days: Set<Date>, cal: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        var day = cal.startOfDay(for: .now)
        // If today isn't logged yet, the streak still stands as of yesterday.
        if !days.contains(day) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day), days.contains(yesterday)
            else { return 0 }
            day = yesterday
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    nonisolated static func longestStreak(days: Set<Date>, cal: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1, run = 1
        for i in 1..<sorted.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]), prev == sorted[i] {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: Widget snapshot

    private func exportSnapshot() {
        BreatheSnapshot(
            currentStreak: currentStreak, longestStreak: longestStreak,
            totalSessions: totalSessions, totalMinutes: totalMinutes,
            didBreatheToday: didBreatheToday, lastPatternName: lastPatternName,
            generatedAt: .now
        ).save()
    }

    // MARK: Patterns

    /// Built-in presets plus any custom patterns (custom only shown to Pro users).
    func patterns(isPro: Bool) -> [BreathPattern] {
        BreathPattern.builtIn + (isPro ? customPatterns : [])
    }

    func pattern(id: String) -> BreathPattern {
        BreathPattern.builtIn(id: id) ?? customPatterns.first { $0.id == id } ?? .box
    }

    private func loadCustom() {
        guard let data = UserDefaults.standard.data(forKey: kCustom),
              let dtos = try? JSONDecoder().decode([CustomPatternDTO].self, from: data) else { return }
        // Drop any degenerate (corrupted) pattern so a zero-length rhythm can never be selected.
        customPatterns = dtos.filter { $0.inhale >= 1 && $0.exhale >= 1 }.map { $0.asPattern() }
    }

    /// Erase all on-device data (used by Delete Account).
    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: BreathSession.self)
        try? ctx.save()
        customPatterns.removeAll()
        UserDefaults.standard.removeObject(forKey: kCustom)
        refresh()
    }

    private func persistCustom() {
        let dtos = customPatterns.map {
            CustomPatternDTO(id: $0.id, name: $0.name, inhale: $0.inhale,
                             holdIn: $0.holdIn, exhale: $0.exhale, holdOut: $0.holdOut)
        }
        if let data = try? JSONEncoder().encode(dtos) {
            UserDefaults.standard.set(data, forKey: kCustom)
        }
    }

    @discardableResult
    func addCustomPattern(name: String, inhale: Double, holdIn: Double,
                          exhale: Double, holdOut: Double) -> BreathPattern {
        let dto = CustomPatternDTO(id: "custom-\(UUID().uuidString.prefix(8))",
                                   name: name.isEmpty ? "Custom" : name,
                                   inhale: inhale, holdIn: holdIn, exhale: exhale, holdOut: holdOut)
        let pattern = dto.asPattern()
        // Defense-in-depth: custom patterns are a Pro bonus — never persist one for a free user,
        // even if a caller reaches here past the UI gate.
        guard store?.isPro == true else { return pattern }
        customPatterns.append(pattern)
        persistCustom()
        return pattern
    }

    func deleteCustomPattern(id: String) {
        customPatterns.removeAll { $0.id == id }
        persistCustom()
    }

    // MARK: DEBUG seeding (compiled out of Release)

    #if DEBUG
    private func seedIfRequested() {
        let env = ProcessInfo.processInfo.environment
        guard let n = env["EASE_SEED"].flatMap(Int.init), n > 0 else { return }
        let ctx = container.mainContext
        if ((try? ctx.fetch(FetchDescriptor<BreathSession>()))?.isEmpty ?? true) {
            let cal = Calendar.current
            for offset in 0..<n {
                if let day = cal.date(byAdding: .day, value: -offset, to: .now) {
                    let p = BreathPattern.free[offset % BreathPattern.free.count]
                    ctx.insert(BreathSession(date: day, patternID: p.id, patternName: p.name,
                                             seconds: [60, 120, 180][offset % 3]))
                }
            }
            try? ctx.save()
        }
    }
    #endif
}
