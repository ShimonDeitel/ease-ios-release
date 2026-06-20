import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @EnvironmentObject var account: AccountManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ease.theme") private var themeRaw = AppTheme.system.rawValue
    @AppStorage("ease.haptics") private var hapticsEnabled = true
    @AppStorage("ease.reminderOn") private var reminderOn = false
    @AppStorage("ease.reminderHour") private var reminderHour = 9
    @AppStorage("ease.reminderMinute") private var reminderMinute = 0

    @State private var showPaywall = false
    @State private var showBuilder = false
    @State private var showDeleteConfirm = false
    @State private var restoreMessage: String?

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Ease \(v)"
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
            },
            set: { newValue in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = c.hour ?? 9
                reminderMinute = c.minute ?? 0
                if reminderOn { Reminders.schedule(hour: reminderHour, minute: reminderMinute) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                sessionSection
                if store.isPro { customPatternsSection }
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .tint(Color.easeAccent)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showBuilder) { PatternBuilderView() }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    appModel.deleteAllData()
                    account.deleteAccount()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account and erases your sessions on this device and from iCloud. This can't be undone.")
            }
        }
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if store.isPro {
                HStack {
                    Label("Ease Pro", systemImage: "sparkles")
                    Spacer()
                    Text("Unlocked").foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Haptics.tap(); showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Ease Pro", systemImage: "sparkles")
                        Spacer()
                        Text(store.displayPrice).foregroundStyle(.secondary)
                    }
                }
                Button("Restore Purchase") {
                    Task {
                        await store.restore()
                        restoreMessage = store.isPro ? "Restored." : "No previous purchase found."
                    }
                }
                if let restoreMessage {
                    Text(restoreMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !store.isPro {
                Text("One-time purchase. Custom patterns, more presets, full history & the streak widget.")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $themeRaw) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var sessionSection: some View {
        Section("Session") {
            Toggle("Haptics", isOn: $hapticsEnabled)
            Toggle("Daily reminder", isOn: $reminderOn)
                .onChange(of: reminderOn) { _, on in
                    if on {
                        Task {
                            let granted = await Reminders.requestAuthorization()
                            if granted {
                                Reminders.schedule(hour: reminderHour, minute: reminderMinute)
                            } else {
                                reminderOn = false
                            }
                        }
                    } else {
                        Reminders.cancel()
                    }
                }
            if reminderOn {
                DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var customPatternsSection: some View {
        Section("Custom patterns") {
            ForEach(appModel.customPatterns) { p in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name).font(.body)
                        Text(p.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .onDelete { idx in
                idx.map { appModel.customPatterns[$0].id }.forEach(appModel.deleteCustomPattern)
            }
            Button {
                Haptics.tap(); showBuilder = true
            } label: {
                Label("New pattern", systemImage: "plus")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            if account.isSignedIn {
                HStack {
                    Text("Signed in")
                    Spacer()
                    Text(account.displayName.isEmpty ? "Apple ID" : account.displayName)
                        .foregroundStyle(.secondary)
                }
                Button("Sign Out", role: .destructive) { account.signOut() }
                Button("Delete Account", role: .destructive) { showDeleteConfirm = true }
            }
            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/ease-site/privacy.html")!)
        } footer: {
            Text(version).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
        }
    }
}
