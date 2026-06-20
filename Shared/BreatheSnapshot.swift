import Foundation

/// Lightweight snapshot written to the App Group after every session, read by the widget.
/// Kept tiny and Codable so the widget never touches SwiftData.
struct BreatheSnapshot: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var totalSessions: Int
    var totalMinutes: Int
    var didBreatheToday: Bool
    var lastPatternName: String
    var generatedAt: Date

    static let placeholder = BreatheSnapshot(
        currentStreak: 3, longestStreak: 7, totalSessions: 24, totalMinutes: 41,
        didBreatheToday: false, lastPatternName: "Box", generatedAt: Date(timeIntervalSince1970: 0)
    )

    static func load() -> BreatheSnapshot {
        guard let url = AppGroup.snapshotURL,
              let data = try? Data(contentsOf: url),
              let snap = try? JSONDecoder.ease.decode(BreatheSnapshot.self, from: data)
        else { return .placeholder }
        return snap
    }

    func save() {
        guard let url = AppGroup.snapshotURL,
              let data = try? JSONEncoder.ease.encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

extension JSONEncoder {
    static var ease: JSONEncoder {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }
}
extension JSONDecoder {
    static var ease: JSONDecoder {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }
}
