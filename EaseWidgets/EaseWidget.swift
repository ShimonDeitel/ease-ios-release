import WidgetKit
import SwiftUI

private let accent = Color(hex: "#007AFF")

struct EaseEntry: TimelineEntry {
    let date: Date
    let snapshot: BreatheSnapshot
}

struct EaseProvider: TimelineProvider {
    func placeholder(in context: Context) -> EaseEntry {
        EaseEntry(date: Date(), snapshot: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (EaseEntry) -> Void) {
        completion(EaseEntry(date: Date(), snapshot: BreatheSnapshot.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<EaseEntry>) -> Void) {
        // The app reloads timelines after each session; this fallback refreshes around midnight
        // so "breathed today" resets even if the app isn't opened.
        let snap = BreatheSnapshot.load()
        let next = Calendar.current.nextDate(after: Date(),
                                             matching: DateComponents(hour: 0, minute: 5),
                                             matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [EaseEntry(date: Date(), snapshot: snap)], policy: .after(next)))
    }
}

struct EaseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EaseWidget", provider: EaseProvider()) { entry in
            EaseWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
        }
        .configurationDisplayName("Ease")
        .description("Your breathing streak and a one-tap breath.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct EaseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: EaseEntry

    // Derive freshness from when the snapshot was written so a stale widget doesn't claim
    // "breathed today" or an inflated streak after a day rolls over without an app open.
    private var didToday: Bool {
        entry.snapshot.didBreatheToday && Calendar.current.isDateInToday(entry.snapshot.generatedAt)
    }
    private var streak: Int {
        let cal = Calendar.current
        let gen = cal.startOfDay(for: entry.snapshot.generatedAt)
        let today = cal.startOfDay(for: entry.date)
        if let d = cal.dateComponents([.day], from: gen, to: today).day, d > 1 { return 0 }
        return entry.snapshot.currentStreak
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(streak > 0 ? "\(streak)-day streak" : "Breathe", systemImage: "wind")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "wind").font(.caption2)
                    Text("\(streak)").font(.title3.bold())
                }
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: didToday ? "checkmark.circle.fill" : "wind")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(streak > 0 ? "\(streak)-day streak" : "Start your streak").font(.headline)
                    Text(didToday ? "Breathed today" : "Tap to breathe").font(.caption2).foregroundStyle(.secondary)
                }
            }
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "wind").font(.headline).foregroundStyle(accent)
                Spacer()
                if didToday {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(accent)
                }
            }
            Spacer()
            Text("\(streak)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
            Text(streak == 1 ? "day streak" : "days streak")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(didToday ? "Calm for today" : "Time to breathe")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}
