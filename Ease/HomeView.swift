import SwiftUI

struct HomeView: View {
    var forceScreen: String?

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @AppStorage("ease.pattern") private var patternID = "box"
    @AppStorage("ease.length") private var lengthSeconds = 60
    @AppStorage("ease.haptics") private var hapticsEnabled = true

    @State private var idlePulse = false
    @State private var showSession = false
    @State private var showStats = false
    @State private var showSettings = false
    @State private var showPaywall = false

    private var selected: BreathPattern {
        let p = appModel.pattern(id: patternID)
        return (p.isPro && !store.isPro) ? .box : p
    }

    private var allChips: [BreathPattern] {
        BreathPattern.builtIn + (store.isPro ? appModel.customPatterns : [])
    }

    var body: some View {
        ZStack {
            EaseBackground()
            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                circle
                Spacer(minLength: 8)
                patternPicker
                lengthPicker.padding(.top, 18)
                breatheButton.padding(.top, 22)
                Spacer().frame(height: 12)
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(isPresented: $showSession) {
            SessionView(pattern: selected, seconds: lengthSeconds)
        }
        .sheet(isPresented: $showStats) { StatsView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear {
            idlePulse = true
            appModel.refresh()
            applyForceScreen()
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(appModel.currentStreak > 0 ? Color.easeAccent : .secondary)
                Text(appModel.currentStreak > 0 ? "\(appModel.currentStreak)-day streak" : "Start your streak")
                    .font(.subheadline.weight(.semibold))
            }
            .easePill()

            Spacer()

            Button { Haptics.tap(); showStats = true } label: {
                Image(systemName: "chart.bar.fill").font(.title3)
            }
            .tint(.primary)
            .padding(.trailing, 14)
            .accessibilityIdentifier("open-stats")
            .accessibilityLabel("Statistics")

            Button { Haptics.tap(); showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.title3)
            }
            .tint(.primary)
            .accessibilityIdentifier("open-settings")
            .accessibilityLabel("Settings")
        }
        .padding(.top, 8)
    }

    private var circle: some View {
        VStack(spacing: 18) {
            BreathingCircle(scale: idlePulse ? 0.82 : 0.6)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: idlePulse)
            VStack(spacing: 4) {
                Text(selected.name).font(.title2.weight(.bold))
                Text(selected.blurb).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var patternPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allChips) { p in
                    let locked = p.isPro && !store.isPro
                    PatternChip(pattern: p, selected: p.id == selected.id, locked: locked) {
                        Haptics.tap()
                        if locked { showPaywall = true } else { patternID = p.id }
                    }
                }
                addCustomChip
            }
            .padding(.horizontal, 2)
        }
    }

    private var addCustomChip: some View {
        Button {
            Haptics.tap()
            if store.isPro { showSettings = true } else { showPaywall = true }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "plus").font(.subheadline.weight(.bold))
                Text("Custom").font(.caption2)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .frame(minWidth: 64)
            .background(Color.easeCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var lengthPicker: some View {
        HStack(spacing: 10) {
            ForEach(SessionLength.options) { len in
                LengthChip(length: len, selected: len.seconds == lengthSeconds) {
                    Haptics.tap(); lengthSeconds = len.seconds
                }
            }
        }
    }

    private var breatheButton: some View {
        Button {
            Haptics.soft(); showSession = true
        } label: {
            Text("Breathe").frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .prominentButton()
        .accessibilityIdentifier("breathe")
    }

    private func applyForceScreen() {
        guard let s = forceScreen else { return }
        switch s {
        case "stats": showStats = true
        case "settings": showSettings = true
        case "paywall": showPaywall = true
        case "session": showSession = true
        default: break
        }
    }
}
