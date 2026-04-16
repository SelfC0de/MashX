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

struct DeleteAccountRequest: Encodable {
    let password: String
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

enum AuthState { case splash, unauthenticated, authenticated }

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var state: AuthState = .splash
    @Published var currentUser: APIUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recoveryCode: String?

    private init() {}

    func checkSession() async {
        guard let token = KeychainService.load(key: "access_token") else {
            state = .unauthenticated; return
        }
        _ = token
        do {
            let user: APIUser = try await APIClient.shared.request(url: API.User.me)
            currentUser = user
            syncSettings(from: user)
            state = .authenticated
        } catch APIError.unauthorized {
            await tryRefresh()
        } catch APIError.notFound {
            // Пользователь удалён из БД
            clearSession()
        } catch {
            state = .unauthenticated
        }
    }

    private func tryRefresh() async {
        guard let refresh = KeychainService.load(key: "refresh_token") else {
            state = .unauthenticated; return
        }
        do {
            struct RefreshResp: Decodable { let access_token: String; let refresh_token: String }
            let resp: RefreshResp = try await APIClient.shared.request(
                url: API.Auth.refresh, method: .POST,
                body: RefreshRequest(refresh_token: refresh), auth: false)
            KeychainService.save(resp.access_token,  key: "access_token")
            KeychainService.save(resp.refresh_token, key: "refresh_token")
            await checkSession()
        } catch {
            KeychainService.clear()
            state = .unauthenticated
        }
    }

    func register(username: String, displayName: String, password: String) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let resp: AuthResponse = try await APIClient.shared.request(
                url: API.Auth.register, method: .POST,
                body: RegisterRequest(
                    username: username.lowercased().trimmingCharacters(in: .whitespaces),
                    display_name: displayName.trimmingCharacters(in: .whitespaces),
                    password: password),
                auth: false)
            saveSession(resp)
            recoveryCode = resp.recovery_code
            currentUser = resp.user
            syncSettings(from: resp.user)
            state = .authenticated
        } catch { errorMessage = error.localizedDescription }
    }

    func login(username: String, password: String) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let resp: AuthResponse = try await APIClient.shared.request(
                url: API.Auth.login, method: .POST,
                body: LoginRequest(
                    username: username.lowercased().trimmingCharacters(in: .whitespaces),
                    password: password,
                    device_name: UIDevice.current.name,
                    device_os: "iOS \(UIDevice.current.systemVersion)"),
                auth: false)
            saveSession(resp)
            currentUser = resp.user
            syncSettings(from: resp.user)
            state = .authenticated
        } catch { errorMessage = error.localizedDescription }
    }

    func recover(username: String, code: String, newPassword: String) async -> Bool {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        struct RecoverResp: Decodable { let message: String; let new_recovery_code: String }
        do {
            let resp: RecoverResp = try await APIClient.shared.request(
                url: API.Auth.recover, method: .POST,
                body: RecoverRequest(username: username.lowercased(), recovery_code: code, new_password: newPassword),
                auth: false)
            recoveryCode = resp.new_recovery_code
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func logout() async {
        let refresh = KeychainService.load(key: "refresh_token") ?? ""
        _ = try? await APIClient.shared.request(
            url: API.Auth.logout, method: .POST,
            body: RefreshRequest(refresh_token: refresh)) as EmptyResponse
        clearSession()
    }

    func deleteAccount(password: String) async -> Bool {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await APIClient.shared.request(
                url: API.User.me, method: .DELETE,
                body: DeleteAccountRequest(password: password)) as EmptyResponse
            clearSession()
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    private func clearSession() {
        KeychainService.clear()
        currentUser = nil
        recoveryCode = nil
        state = .unauthenticated
    }

    private func saveSession(_ resp: AuthResponse) {
        KeychainService.save(resp.access_token,  key: "access_token")
        KeychainService.save(resp.refresh_token, key: "refresh_token")
        KeychainService.save(resp.user.id,       key: "user_id")
        KeychainService.save(resp.user.username, key: "username")
    }

    private func syncSettings(from user: APIUser) {
        let s = SettingsStore.shared
        let key = "settings_synced_\(user.id)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        s.notificationsEnabled = user.notifications
        s.soundEnabled         = user.sound_enabled
        // showOnlineStatus и offlineMode — только локальные, не перезаписываем с сервера
        s.sendReadReceipts     = user.send_receipts
        s.antispam             = user.antispam
        s.smartReply           = user.smart_reply
        s.e2eEnabled           = user.e2e_enabled
        s.accentIndex          = user.accent_index
        s.fontSizeIndex        = user.font_size_index
        s.languageIndex        = user.language_index
        UserDefaults.standard.set(true, forKey: key)
    }

    func updateOnlineStatus(_ online: Bool) async {
        struct Patch: Encodable { let show_online: Bool }
        do {
            _ = try await APIClient.shared.request(
                url: API.User.me, method: .PATCH,
                body: Patch(show_online: online)) as EmptyResponse
            if let u = currentUser {
                currentUser = APIUser(
                    id: u.id, username: u.username, display_name: u.display_name,
                    avatar_url: u.avatar_url, bio: u.bio,
                    is_online: online, show_online: online,
                    send_receipts: u.send_receipts, antispam: u.antispam,
                    smart_reply: u.smart_reply, e2e_enabled: u.e2e_enabled,
                    notifications: u.notifications, sound_enabled: u.sound_enabled,
                    accent_index: u.accent_index, font_size_index: u.font_size_index,
                    language_index: u.language_index)
            }
        } catch {}
    }
}

struct EmptyResponse: Decodable {}

import UIKit
