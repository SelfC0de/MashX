import SwiftUI

@main
struct MashXApp: App {
    @StateObject private var settings     = SettingsStore.shared
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var authManager  = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(settings)
                .environmentObject(toastManager)
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct AppRootView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var toast: ToastManager
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            switch auth.state {
            case .splash:
                SplashView()
            case .unauthenticated:
                AuthRootView()
                    .transition(.opacity)
            case .authenticated:
                RootView()
                    .transition(.opacity)
            }
            ToastOverlay()
        }
        .animation(.easeInOut(duration: 0.3), value: auth.state == .authenticated)
        .task { await auth.checkSession() }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.accentProfile.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Text("MX")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.accentProfile)
                }
                Text("MashX")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.text)
                ProgressView().tint(Theme.accentProfile)
            }
        }
    }
}
