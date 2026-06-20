import Foundation
import SwiftData

/// One completed breathing session. All properties have defaults and there are no unique
/// constraints, so the schema is CloudKit-mirroring compatible.
@Model
final class BreathSession {
    var id: UUID = UUID()
    var date: Date = Date.now
    var patternID: String = "box"
    var patternName: String = "Box"
    var seconds: Int = 60

    init(id: UUID = UUID(), date: Date = .now, patternID: String = "box",
         patternName: String = "Box", seconds: Int = 60) {
        self.id = id
        self.date = date
        self.patternID = patternID
        self.patternName = patternName
        self.seconds = seconds
    }
}
