import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                EaseBackground()
                ScrollView {
                    LazyVGrid(columns: cols, spacing: 12) {
                        MetricTile(value: "\(appModel.currentStreak)", label: "Day streak")
                        MetricTile(value: "\(appModel.longestStreak)", label: "Best streak")
                        MetricTile(value: "\(appModel.sessionsThisWeek)", label: "This week")
                        MetricTile(value: "\(appModel.totalSessions)", label: "Sessions")
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    MetricTile(value: "\(appModel.totalMinutes)", label: "Total minutes of calm")
                        .padding(.horizontal)

                    historySection.padding(.top, 6)
                }
            }
            .navigationTitle("Your calm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History").font(.headline).padding(.horizontal)

            if store.isPro {
                let sessions = appModel.recentSessions()
                if sessions.isEmpty {
                    Text("Your sessions will appear here.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 0) {
                        ForEach(sessions) { s in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.patternName).font(.subheadline.weight(.medium))
                                    Text(s.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(max(1, s.seconds / 60)) min")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 12).padding(.horizontal, 16)
                            if s.id != sessions.last?.id { Divider().padding(.leading, 16) }
                        }
                    }
                    .background(Color.easeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal)
                }
            } else {
                Button { Haptics.tap(); showPaywall = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").foregroundStyle(Color.easeAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("See your full history").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Text("Every session and all-time stats with Ease Pro").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color.easeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 30)
    }
}
