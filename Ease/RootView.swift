import SwiftUI

struct RootView: View {
    @EnvironmentObject var account: AccountManager
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @AppStorage("ease.theme") private var themeRaw = AppTheme.system.rawValue

    @State private var debugBypassAuth = false
    @State private var forceScreen: String?

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .system }
    private var gateOpen: Bool {
        #if EASE_NO_AUTH
        // Device-trial builds signed with a personal team that can't provision Sign in with Apple
        // skip the auth gate so the breathing experience runs. Never set in App Store builds.
        return true
        #else
        return account.isSignedIn || debugBypassAuth
        #endif
    }

    var body: some View {
        Group {
            if gateOpen {
                HomeView(forceScreen: forceScreen)
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .onChange(of: store.isPro) { _, _ in appModel.refresh() }
        .onAppear {
            #if DEBUG
            let env = ProcessInfo.processInfo.environment
            if env["EASE_SKIP_AUTH"] == "1" { debugBypassAuth = true }
            forceScreen = env["EASE_SCREEN"]
            #endif
        }
    }
}
