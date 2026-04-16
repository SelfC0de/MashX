import Foundation

enum HTTPMethod: String {
    case GET, POST, PATCH, DELETE
}

enum APIError: LocalizedError {
    case network(String)
    case server(String)
    case unauthorized
    case notFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let m):  return "Ошибка сети: \(m)"
        case .server(let m):   return m
        case .unauthorized:    return "Необходима авторизация"
        case .notFound:        return "Не найдено"
        case .unknown:         return "Неизвестная ошибка"
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private var accessToken: String? { KeychainService.load(key: "access_token") }

    func request<T: Decodable>(
        url: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        auth: Bool = true
    ) async throws -> T {
        guard let reqURL = URL(string: url) else {
            throw APIError.network("Неверный URL")
        }

        var req = URLRequest(url: reqURL)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(deviceName(), forHTTPHeaderField: "X-Device-Name")
        let osVersion = await MainActor.run { UIDevice.current.systemVersion }
        req.setValue("iOS \(osVersion)", forHTTPHeaderField: "X-Device-OS")

        if auth, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch http.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            if let errBody = try? JSONDecoder().decode([String: String].self, from: data),
               let msg = errBody["error"] {
                throw APIError.server(msg)
            }
            throw APIError.server("Ошибка сервера (\(http.statusCode))")
        }
    }

    // Multipart upload для аватара
    func uploadAvatar(imageData: Data, mimeType: String) async throws -> String {
        guard let url = URL(string: API.User.avatar),
              let token = accessToken else {
            throw APIError.unauthorized
        }

        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let ext = mimeType == "image/png" ? "png" : "jpg"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.\(ext)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: req)
        if let result = try? JSONDecoder().decode([String: String].self, from: data),
           let avatarURL = result["avatar_url"] {
            return avatarURL
        }
        throw APIError.server("Не удалось загрузить аватар")
    }

    private func deviceName() -> String {
        var info = utsname()
        uname(&info)
        let machine = withUnsafeBytes(of: &info.machine) { ptr -> String in
            let bytes = ptr.bindMemory(to: CChar.self)
            return String(cString: bytes.baseAddress!)
        }
        return machine
    }
}

import UIKit
