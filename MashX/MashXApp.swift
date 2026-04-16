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

    @State private var splashDone = false

    var body: some View {
        ZStack {
            switch auth.state {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .unauthenticated:
                if splashDone {
                    AuthRootView()
                        .transition(.opacity)
                        .onAppear { WebSocketManager.shared.disconnect() }
                } else {
                    SplashView()
                        .transition(.opacity)
                }
            case .authenticated:
                if splashDone {
                    RootView()
                        .transition(.opacity)
                        .onAppear {
                            WebSocketManager.shared.connect()
                            SoundManager.shared.requestPermission()
                        }
                } else {
                    SplashView()
                        .transition(.opacity)
                }
            }
            ToastOverlay()
        }
        .animation(.easeInOut(duration: 0.4), value: auth.state == .authenticated)
        .animation(.easeInOut(duration: 0.4), value: splashDone)
        .task {
            // Запускаем checkSession и минимальный таймер параллельно
            async let session: () = auth.checkSession()
            async let delay: () = {
                try? await Task.sleep(nanoseconds: 1_800_000_000) // 1.8 сек
            }()
            _ = await (session, delay)
            withAnimation { splashDone = true }
        }
    }
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.accentProfile.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 24)
                            .stroke(Theme.accentProfile.opacity(0.3), lineWidth: 1))
                    Text("MX")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.accentProfile)
                }
                .scaleEffect(scale)

                Text("MashX")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.text)

                ProgressView().tint(Theme.accentProfile)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            SoundManager.shared.playSplash()
        }
    }
}
