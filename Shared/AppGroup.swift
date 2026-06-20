import Foundation

/// Single source of truth for the App Group used to share the streak snapshot with the widget.
enum AppGroup {
    static let identifier = "group.com.easeapp.shared"
    static let snapshotFilename = "ease_snapshot.json"

    static var containerURL: URL? {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        #if DEBUG
        if url == nil {
            assertionFailure("App Group container is nil — check the App Group capability/entitlement for \(identifier).")
        }
        #endif
        return url
    }

    static var snapshotURL: URL? {
        containerURL?.appendingPathComponent(snapshotFilename)
    }
}
