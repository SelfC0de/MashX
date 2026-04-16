import Foundation
import Combine

// MARK: - WS Event Models

struct WSInEvent: Encodable {
    let type: String
    let data: AnyEncodable
}

struct WSMessage: Decodable, Identifiable {
    let id: String
    let temp_id: String?
    let conversation_id: String?
    let group_id: String?
    let sender_id: String
    let sender_username: String?
    let sender_display_name: String?
    let sender_avatar_url: String?
    let content: String
    let content_type: String
    let reply_to_id: String?
    let deleted_at: String?
    let deleted_content: String?
    let is_deleted: Bool?
    let is_outgoing: Bool?
    let created_at: String
}

struct WSDeleteEvent: Decodable {
    let message_id: String
    let conversation_id: String?
    let group_id: String?
    let deleted_by: String
}

struct WSTypingEvent: Decodable {
    let sender_id: String
    let conversation_id: String?
    let group_id: String?
    let typing: Bool
}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

// MARK: - WebSocketManager

@MainActor
final class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false

    // Publishers для подписки во вью
    let messageReceived   = PassthroughSubject<WSMessage, Never>()
    let messageDeleted    = PassthroughSubject<WSDeleteEvent, Never>()
    let typingReceived    = PassthroughSubject<WSTypingEvent, Never>()

    private var task: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private var reconnectTask: Task<Void, Never>?
    private var shouldReconnect = true

    private init() {}

    func connect() {
        guard let token = KeychainService.load(key: "access_token") else { return }
        shouldReconnect = true
        openConnection(token: token)
    }

    func disconnect() {
        shouldReconnect = false
        pingTimer?.invalidate()
        reconnectTask?.cancel()
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
    }

    private func openConnection(token: String) {
        let urlStr = "wss://metallurgfk.ru/api/ws"
        guard var comps = URLComponents(string: urlStr) else { return }
        comps.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = comps.url else { return }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        task = URLSession.shared.webSocketTask(with: req)
        task?.resume()
        isConnected = true

        startPing()
        receiveLoop()
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let msg):
                if case .string(let text) = msg {
                    Task { @MainActor in self.handle(text) }
                }
                self.receiveLoop()
            case .failure:
                Task { @MainActor in self.handleDisconnect() }
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String,
              let eventData = json["data"] else { return }

        let dataBytes = (try? JSONSerialization.data(withJSONObject: eventData)) ?? Data()

        switch type {
        case "message":
            if let m = try? JSONDecoder().decode(WSMessage.self, from: dataBytes) {
                messageReceived.send(m)
            }
        case "message_delete":
            if let d = try? JSONDecoder().decode(WSDeleteEvent.self, from: dataBytes) {
                messageDeleted.send(d)
            }
        case "typing":
            if let t = try? JSONDecoder().decode(WSTypingEvent.self, from: dataBytes) {
                typingReceived.send(t)
            }
        default: break
        }
    }

    // MARK: - Send

    func sendMessage(partnerID: String? = nil, convID: String? = nil, groupID: String? = nil,
                     content: String, contentType: String = "text",
                     replyToID: String? = nil, tempID: String) {
        struct Payload: Encodable {
            let partner_id: String?
            let conversation_id: String?
            let group_id: String?
            let content: String
            let content_type: String
            let reply_to_id: String?
            let temp_id: String
        }
        send(type: "message", data: Payload(
            partner_id: partnerID, conversation_id: convID, group_id: groupID,
            content: content, content_type: contentType,
            reply_to_id: replyToID, temp_id: tempID))
    }

    func sendTyping(partnerID: String? = nil, convID: String? = nil, groupID: String? = nil, typing: Bool) {
        struct Payload: Encodable {
            let partner_id: String?
            let conversation_id: String?
            let group_id: String?
            let typing: Bool
        }
        send(type: "typing", data: Payload(
            partner_id: partnerID, conversation_id: convID, group_id: groupID, typing: typing))
    }

    func sendReadReceipts(messageIDs: [String]) {
        struct Payload: Encodable { let message_ids: [String] }
        send(type: "message_read", data: Payload(message_ids: messageIDs))
    }

    private func send<T: Encodable>(type: String, data: T) {
        guard let task, isConnected else { return }
        let ev = WSInEvent(type: type, data: AnyEncodable(data))
        guard let bytes = try? JSONEncoder().encode(ev),
              let str = String(data: bytes, encoding: .utf8) else { return }
        task.send(.string(str)) { _ in }
    }

    // MARK: - Ping / Reconnect

    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.task?.sendPing { _ in }
        }
    }

    private func handleDisconnect() {
        isConnected = false
        pingTimer?.invalidate()
        guard shouldReconnect else { return }
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { self.connect() }
        }
    }
}
