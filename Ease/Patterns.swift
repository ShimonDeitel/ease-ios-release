import Foundation

/// A breathing pattern: durations (seconds) for each phase. `holdOut`/`holdIn` of 0 are skipped.
struct BreathPattern: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let detail: String     // "4·4·4·4"
    let blurb: String      // one-line description
    let inhale: Double
    let holdIn: Double
    let exhale: Double
    let holdOut: Double
    let isPro: Bool
    let isCustom: Bool

    init(id: String, name: String, detail: String, blurb: String,
         inhale: Double, holdIn: Double, exhale: Double, holdOut: Double,
         isPro: Bool = false, isCustom: Bool = false) {
        self.id = id; self.name = name; self.detail = detail; self.blurb = blurb
        self.inhale = inhale; self.holdIn = holdIn; self.exhale = exhale; self.holdOut = holdOut
        self.isPro = isPro; self.isCustom = isCustom
    }

    var cycleSeconds: Double { inhale + holdIn + exhale + holdOut }

    // MARK: Free presets — genuinely complete on their own.
    static let box = BreathPattern(id: "box", name: "Box", detail: "4·4·4·4",
        blurb: "Steady focus and calm", inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)
    static let relax = BreathPattern(id: "relax", name: "Relax", detail: "4·7·8",
        blurb: "Melt into sleep", inhale: 4, holdIn: 7, exhale: 8, holdOut: 0)
    static let even = BreathPattern(id: "even", name: "Even", detail: "5·5",
        blurb: "Balanced and grounded", inhale: 5, holdIn: 0, exhale: 5, holdOut: 0)

    // MARK: Pro preset bonuses.
    static let unwind = BreathPattern(id: "unwind", name: "Unwind", detail: "4·2·8",
        blurb: "A long exhale to let go", inhale: 4, holdIn: 2, exhale: 8, holdOut: 0, isPro: true)
    static let resonance = BreathPattern(id: "resonance", name: "Resonance", detail: "5.5·5.5",
        blurb: "Heart-rate coherence", inhale: 5.5, holdIn: 0, exhale: 5.5, holdOut: 0, isPro: true)
    static let centered = BreathPattern(id: "centered", name: "Centered", detail: "4·4·6·2",
        blurb: "Settle and reset", inhale: 4, holdIn: 4, exhale: 6, holdOut: 2, isPro: true)

    static let free: [BreathPattern] = [box, relax, even]
    static let proPresets: [BreathPattern] = [unwind, resonance, centered]
    static let builtIn: [BreathPattern] = free + proPresets

    static func builtIn(id: String) -> BreathPattern? { builtIn.first { $0.id == id } }
}

/// Session lengths offered on the home screen.
struct SessionLength: Identifiable, Equatable {
    let seconds: Int
    var id: Int { seconds }
    var label: String { "\(seconds / 60) min" }
    static let options: [SessionLength] = [
        .init(seconds: 60), .init(seconds: 120), .init(seconds: 180), .init(seconds: 300)
    ]
}

/// Codable form of a user-built custom pattern (Pro). Persisted in UserDefaults.
struct CustomPatternDTO: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var inhale: Double
    var holdIn: Double
    var exhale: Double
    var holdOut: Double

    func asPattern() -> BreathPattern {
        func fmt(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v) }
        var parts = [fmt(inhale)]
        if holdIn > 0 { parts.append(fmt(holdIn)) }
        parts.append(fmt(exhale))
        if holdOut > 0 { parts.append(fmt(holdOut)) }
        return BreathPattern(id: id, name: name, detail: parts.joined(separator: "·"),
                             blurb: "Your custom rhythm", inhale: inhale, holdIn: holdIn,
                             exhale: exhale, holdOut: holdOut, isPro: true, isCustom: true)
    }
}
