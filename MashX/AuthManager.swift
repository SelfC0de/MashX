import SwiftUI

// MARK: - API DTOs
struct RegisterRequest: Encodable {
    let username: String
    let display_name: String
    let password: String
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
    let device_name: String
    let device_os: String
}

struct RefreshRequest: Encodable {
    let refresh_token: String
}

struct RecoverRequest: Encodable {
    let username: String
    let recovery_code: String
    let new_password: String
}

struct AuthResponse: Decodable {
    let user: APIUser
    let access_token: String
    let refresh_token: String
    let recovery_code: String?
}

struct APIUser: Decodable {
    let id: String
    let username: String
    let display_name: String
    let avatar_url: String
    let bio: String
    let is_online: Bool
    let show_online: Bool
    let send_receipts: Bool
    let antispam: Bool
    let smart_reply: Bool
    let e2e_enabled: Bool
    let notifications: Bool
    let sound_enabled: Bool
    let accent_index: Int
    let font_size_index: Int
    let language_index: Int
}

// MARK: - AuthState
enum AuthState {
    case splash
    case unauthenticated
    case authenticated
}

// MARK: - AuthManager
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var state: AuthState = .splash
    @Published var currentUser: APIUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recoveryCode: String?

    private init() {}

    // MARK: - Auto login at launch
    func checkSession() async {
        guard let token = KeychainService.load(key: "access_token") else {
            state = .unauthenticated
            return
        }

        do {
            let user: APIUser = try await APIClient.shared.request(url: API.User.me)
            currentUser = user
            syncSettings(from: user)
            state = .authenticated
        } catch APIError.unauthorized {
            await tryRefresh()
        } catch {
            state = .unauthenticated
        }
    }

    private func tryRefresh() async {
        guard let refresh = KeychainService.load(key: "refresh_token") else {
            state = .unauthenticated
            return
        }
        do {
            struct RefreshResp: Decodable {
                let access_token: String
                let refresh_token: String
            }
            let resp: RefreshResp = try await APIClient.shared.request(
                url: API.Auth.refresh,
                method: .POST,
                body: RefreshRequest(refresh_token: refresh),
                auth: false
            )
            KeychainService.save(resp.access_token,  key: "access_token")
            KeychainService.save(resp.refresh_token, key: "refresh_token")
            await checkSession()
        } catch {
            KeychainService.clear()
            state = .unauthenticated
        }
    }

    // MARK: - Register
    func register(username: String, displayName: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let req = RegisterRequest(
            username: username.lowercased().trimmingCharacters(in: .whitespaces),
            display_name: displayName.trimmingCharacters(in: .whitespaces),
            password: password
        )

        do {
            let resp: AuthResponse = try await APIClient.shared.request(
                url: API.Auth.register,
                method: .POST,
                body: req,
                auth: false
            )
            saveSession(resp)
            recoveryCode = resp.recovery_code
            currentUser = resp.user
            syncSettings(from: resp.user)
            state = .authenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Login
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let req = LoginRequest(
            username: username.lowercased().trimmingCharacters(in: .whitespaces),
            password: password,
            device_name: UIDevice.current.name,
            device_os: "iOS \(UIDevice.current.systemVersion)"
        )

        do {
            let resp: AuthResponse = try await APIClient.shared.request(
                url: API.Auth.login,
                method: .POST,
                body: req,
                auth: false
            )
            saveSession(resp)
            currentUser = resp.user
            syncSettings(from: resp.user)
            state = .authenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Recover
    func recover(username: String, code: String, newPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        struct RecoverResp: Decodable {
            let message: String
            let new_recovery_code: String
        }

        do {
            let resp: RecoverResp = try await APIClient.shared.request(
                url: API.Auth.recover,
                method: .POST,
                body: RecoverRequest(
                    username: username.lowercased(),
                    recovery_code: code,
                    new_password: newPassword
                ),
                auth: false
            )
            recoveryCode = resp.new_recovery_code
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Logout
    func logout() async {
        let refresh = KeychainService.load(key: "refresh_token") ?? ""
        _ = try? await APIClient.shared.request(
            url: API.Auth.logout,
            method: .POST,
            body: RefreshRequest(refresh_token: refresh)
        ) as EmptyResponse
        KeychainService.clear()
        currentUser = nil
        state = .unauthenticated
    }

    // MARK: - Helpers
    private func saveSession(_ resp: AuthResponse) {
        KeychainService.save(resp.access_token,   key: "access_token")
        KeychainService.save(resp.refresh_token,  key: "refresh_token")
        KeychainService.save(resp.user.id,        key: "user_id")
        KeychainService.save(resp.user.username,  key: "username")
    }

    private func syncSettings(from user: APIUser) {
        let s = SettingsStore.shared
        s.notificationsEnabled = user.notifications
        s.soundEnabled         = user.sound_enabled
        s.showOnlineStatus     = user.show_online
        s.sendReadReceipts     = user.send_receipts
        s.antispam             = user.antispam
        s.smartReply           = user.smart_reply
        s.e2eEnabled           = user.e2e_enabled
        s.accentIndex          = user.accent_index
        s.fontSizeIndex        = user.font_size_index
        s.languageIndex        = user.language_index
    }
}

struct EmptyResponse: Decodable {}

import UIKit
