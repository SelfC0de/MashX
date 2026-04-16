import SwiftUI
import Combine

// MARK: - API Chat Message
struct APIMessage: Identifiable, Equatable {
    let id: String
    var tempID: String?
    let conversationID: String?
    let groupID: String?
    let senderID: String
    let senderName: String
    let senderAvatar: String
    var content: String
    let contentType: String
    let replyToID: String?
    var isDeleted: Bool
    var deletedContent: String?
    var isOutgoing: Bool
    let createdAt: String

    init(from ws: WSMessage, myID: String) {
        id = ws.id
        tempID = ws.temp_id
        conversationID = ws.conversation_id
        groupID = ws.group_id
        senderID = ws.sender_id
        senderName = ws.sender_display_name ?? ws.sender_username ?? "User"
        senderAvatar = ws.sender_avatar_url ?? ""
        content = ws.content
        contentType = ws.content_type
        replyToID = ws.reply_to_id
        isDeleted = ws.is_deleted ?? false
        deletedContent = ws.deleted_content
        isOutgoing = ws.is_outgoing ?? (ws.sender_id == myID)
        createdAt = ws.created_at
    }
}

// MARK: - ChatDetailView
struct ChatDetailView: View {
    // Для личного чата
    var partnerID: String?
    var partnerName: String
    var partnerAvatar: String
    var isPartnerOnline: Bool
    // Для группового чата
    var groupID: String?
    var convID: String?

    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toast: ToastManager

    @State private var messages: [APIMessage] = []
    @State private var inputText = ""
    @State private var replyTo: APIMessage? = nil
    @State private var showDeletedContent: String? = nil
    @State private var isLoading = false
    @State private var isTyping = false
    @State private var typingTimer: Timer? = nil
    @State private var showDeleteAlert = false
    @State private var deleteTarget: APIMessage? = nil
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var wsManager: WebSocketManager { WebSocketManager.shared }
    private let accent = Theme.accentChats
    private var myID: String { auth.currentUser?.id ?? "" }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                if isLoading && messages.isEmpty {
                    Spacer(); ProgressView().tint(accent); Spacer()
                } else {
                    messageList
                }
                if isTyping { typingRow.transition(.move(edge: .bottom).combined(with: .opacity)) }
                inputBar
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { inputFocused = false }
                    .foregroundColor(accent).fontWeight(.semibold)
            }
        }
        .alert("Удалить сообщение?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                if let msg = deleteTarget { Task { await deleteMessage(msg) } }
            }
        }
        .sheet(item: Binding(
            get: { showDeletedContent.map { IdentifiableString(value: $0) } },
            set: { showDeletedContent = $0?.value }
        )) { item in
            DeletedMessageSheet(content: item.value, accent: accent)
        }
        .task { await loadMessages() }
        .onReceive(wsManager.messageReceived) { handleNewMessage($0) }
        .onReceive(wsManager.messageDeleted)  { handleDeletedMessage($0) }
        .onReceive(wsManager.typingReceived)  { handleTyping($0) }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isTyping)
    }

    // MARK: - NavBar
    private var navBar: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(accent)
            }
            AvatarView(initials: String(partnerName.prefix(2)).uppercased(),
                       size: 36, isOnline: isPartnerOnline && !settings.offlineMode)
            VStack(alignment: .leading, spacing: 1) {
                Text(partnerName).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                Text(isPartnerOnline && !settings.offlineMode ? "онлайн" : "оффлайн")
                    .font(.system(size: 12))
                    .foregroundColor(isPartnerOnline && !settings.offlineMode ? Theme.accentContacts : Theme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.bgSecond)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .bottom)
    }

    // MARK: - Message List
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(messages) { msg in
                        MessageBubbleView(
                            message: msg,
                            myID: myID,
                            accent: accent,
                            onReply: { replyTo = msg },
                            onDelete: { deleteTarget = msg; showDeleteAlert = true },
                            onViewDeleted: { showDeletedContent = msg.deletedContent }
                        )
                        .id(msg.id)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Typing row
    private var typingRow: some View {
        HStack {
            TypingIndicator()
            Text("печатает...").font(.system(size: 11)).foregroundColor(Theme.muted)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.bottom, 4)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            if let reply = replyTo {
                HStack(spacing: 8) {
                    Rectangle().fill(accent).frame(width: 3).cornerRadius(2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reply.isOutgoing ? "Вы" : reply.senderName)
                            .font(.system(size: 11, weight: .semibold)).foregroundColor(accent)
                        Text(reply.isDeleted ? "Удалённое сообщение" : reply.content)
                            .font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
                    }
                    Spacer()
                    Button { replyTo = nil } label: {
                        Image(systemName: "xmark").font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Theme.card)
                .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                TextField("Сообщение...", text: $inputText, axis: .vertical)
                    .font(.system(size: 15)).foregroundColor(Theme.text).tint(accent)
                    .focused($inputFocused).lineLimit(1...5)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.card).cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(inputFocused ? accent.opacity(0.4) : Theme.border, lineWidth: 0.5))
                    .onChange(of: inputText) { _ in handleTypingInput() }

                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(inputText.isEmpty ? Theme.dim : accent)
                        .clipShape(Circle())
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.15), value: inputText.isEmpty)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Theme.bgSecond.overlay(
            Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top))
    }

    // MARK: - Actions

    private func loadMessages() async {
        isLoading = true; defer { isLoading = false }
        guard let partnerID else { return }
        do {
            let raw: [WSMessageRaw] = try await APIClient.shared.request(
                url: "\(API.base)/chats/\(partnerID)/messages")
            messages = raw.map { APIMessage(from: $0.toWSMessage(), myID: myID) }
        } catch {}
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let tempID = UUID().uuidString
        let now = ISO8601DateFormatter().string(from: Date())

        // Оптимистично добавляем в список
        let optimistic = APIMessage(
            id: tempID, tempID: tempID,
            conversationID: convID, groupID: groupID,
            senderID: myID,
            senderName: auth.currentUser?.display_name ?? "You",
            senderAvatar: auth.currentUser?.avatar_url ?? "",
            content: text, contentType: "text",
            replyToID: replyTo?.id,
            isDeleted: false, deletedContent: nil,
            isOutgoing: true, createdAt: now)
        messages.append(optimistic)

        wsManager.sendMessage(
            partnerID: partnerID, convID: convID, groupID: groupID,
            content: text, replyToID: replyTo?.id, tempID: tempID)

        inputText = ""
        replyTo = nil
        wsManager.sendTyping(partnerID: partnerID, convID: convID, groupID: groupID, typing: false)
    }

    private func deleteMessage(_ msg: APIMessage) async {
        do {
            _ = try await APIClient.shared.request(
                url: "\(API.base)/messages/\(msg.id)", method: .DELETE) as EmptyResponse
            if let i = messages.firstIndex(where: { $0.id == msg.id }) {
                messages[i].isDeleted = true
                messages[i].deletedContent = messages[i].content
                messages[i].content = "Сообщение удалено"
            }
        } catch { toast.show("Ошибка удаления", style: .error) }
    }

    private func handleTypingInput() {
        guard let partnerID else { return }
        wsManager.sendTyping(partnerID: partnerID, convID: convID, groupID: groupID, typing: true)
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            Task { @MainActor in
                self.wsManager.sendTyping(partnerID: partnerID, convID: self.convID,
                                          groupID: self.groupID, typing: false)
            }
        }
    }

    private func handleNewMessage(_ ws: WSMessage) {
        let isForThisChat: Bool
        if let gid = groupID {
            isForThisChat = ws.group_id == gid
        } else if let pid = partnerID {
            isForThisChat = ws.sender_id == pid || (ws.is_outgoing == true && ws.sender_id == myID)
        } else {
            isForThisChat = false
        }
        guard isForThisChat else { return }

        // Заменяем оптимистичное сообщение реальным
        if let tempID = ws.temp_id, let i = messages.firstIndex(where: { $0.id == tempID }) {
            messages[i] = APIMessage(from: ws, myID: myID)
        } else if !messages.contains(where: { $0.id == ws.id }) {
            messages.append(APIMessage(from: ws, myID: myID))
        }

        // Отмечаем прочитанным если не наше
        if ws.sender_id != myID {
            wsManager.sendReadReceipts(messageIDs: [ws.id])
        }
    }

    private func handleDeletedMessage(_ ev: WSDeleteEvent) {
        if let i = messages.firstIndex(where: { $0.id == ev.message_id }) {
            messages[i].deletedContent = messages[i].content
            messages[i].content = "Сообщение удалено"
            messages[i].isDeleted = true
        }
    }

    private func handleTyping(_ ev: WSTypingEvent) {
        guard ev.sender_id != myID else { return }
        let relevant: Bool
        if let gid = groupID { relevant = ev.group_id == gid }
        else { relevant = ev.sender_id == partnerID }
        guard relevant else { return }
        withAnimation { isTyping = ev.typing }
        if ev.typing {
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
                Task { @MainActor in withAnimation { self.isTyping = false } }
            }
        }
    }
}

// MARK: - APIMessage full init
extension APIMessage {
    init(id: String, tempID: String?, conversationID: String?, groupID: String?,
         senderID: String, senderName: String, senderAvatar: String,
         content: String, contentType: String, replyToID: String?,
         isDeleted: Bool, deletedContent: String?, isOutgoing: Bool, createdAt: String) {
        self.id = id; self.tempID = tempID
        self.conversationID = conversationID; self.groupID = groupID
        self.senderID = senderID; self.senderName = senderName; self.senderAvatar = senderAvatar
        self.content = content; self.contentType = contentType
        self.replyToID = replyToID; self.isDeleted = isDeleted
        self.deletedContent = deletedContent; self.isOutgoing = isOutgoing
        self.createdAt = createdAt
    }
}

// MARK: - Raw API response → WSMessage
struct WSMessageRaw: Decodable {
    let id: String
    let conversation_id: String?
    let group_id: String?
    let sender_id: String
    let sender: SenderInfo?
    let content: String
    let content_type: String
    let reply_to_id: String?
    let deleted_at: String?
    let deleted_content: String?
    let is_deleted: Bool?
    let is_outgoing: Bool?
    let created_at: String

    struct SenderInfo: Decodable {
        let id: String?
        let username: String?
        let display_name: String?
        let avatar_url: String?
    }

    func toWSMessage() -> WSMessage {
        WSMessage(
            id: id, temp_id: nil,
            conversation_id: conversation_id, group_id: group_id,
            sender_id: sender_id,
            sender_username: sender?.username,
            sender_display_name: sender?.display_name,
            sender_avatar_url: sender?.avatar_url,
            content: content, content_type: content_type,
            reply_to_id: reply_to_id,
            deleted_at: deleted_at, deleted_content: deleted_content,
            is_deleted: is_deleted, is_outgoing: is_outgoing,
            created_at: created_at)
    }
}

// MARK: - MessageBubbleView
struct MessageBubbleView: View {
    let message: APIMessage
    let myID: String
    let accent: Color
    let onReply: () -> Void
    let onDelete: () -> Void
    let onViewDeleted: () -> Void

    var body: some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 3) {
                // Sender name (для групп)
                if !message.isOutgoing && message.groupID != nil {
                    Text(message.senderName)
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(accent)
                        .padding(.leading, 4)
                }

                // Reply preview
                if let replyID = message.replyToID, !replyID.isEmpty {
                    HStack(spacing: 5) {
                        Rectangle().fill(accent).frame(width: 2.5).cornerRadius(1)
                        Text("Ответ на сообщение")
                            .font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(1)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(accent.opacity(0.08)).cornerRadius(8)
                }

                // Bubble
                if message.isDeleted {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill").font(.system(size: 11)).foregroundColor(Theme.dim)
                        Text("Сообщение удалено").font(.system(size: 14)).foregroundColor(Theme.muted).italic()
                        if message.deletedContent != nil {
                            Button { onViewDeleted() } label: {
                                Text("Просмотреть")
                                    .font(.system(size: 11, weight: .semibold)).foregroundColor(accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 0.5))
                } else {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(message.isOutgoing ? .white : Theme.text)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(message.isOutgoing ? accent : Theme.card)
                        .cornerRadius(message.isOutgoing ? 16 : 4, corners: .topLeft)
                        .cornerRadius(message.isOutgoing ? 4 : 16, corners: .topRight)
                        .cornerRadius(16, corners: .bottomLeft)
                        .cornerRadius(16, corners: .bottomRight)
                }

                // Time
                Text(formattedTime(message.createdAt))
                    .font(.system(size: 10)).foregroundColor(Theme.dim)
            }
            .contextMenu {
                Button { onReply() } label: { Label("Ответить", systemImage: "arrowshape.turn.up.left.fill") }
                Button {
                    UIPasteboard.general.string = message.content
                } label: { Label("Копировать", systemImage: "doc.on.clipboard") }
                if message.isOutgoing || message.groupID != nil {
                    Divider()
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Удалить", systemImage: "trash.fill")
                    }
                }
            }

            if !message.isOutgoing { Spacer(minLength: 60) }
        }
        .transition(.asymmetric(
            insertion: .move(edge: message.isOutgoing ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity))
    }

    private func formattedTime(_ str: String) -> String {
        let formatters: [DateFormatter] = [
            { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"; return f }(),
            { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"; return f }(),
        ]
        let out = DateFormatter(); out.dateFormat = "HH:mm"
        for f in formatters {
            if let d = f.date(from: str) { return out.string(from: d) }
        }
        return str.suffix(5).description
    }
}

// MARK: - Deleted Message Sheet
struct DeletedMessageSheet: View {
    let content: String
    let accent: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10)
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill").foregroundColor(accent)
                    Text("Удалённое сообщение").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                }
                Text(content)
                    .font(.system(size: 15)).foregroundColor(Theme.text)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.3), lineWidth: 0.5))
                    .padding(.horizontal, 24)
                Text("Это сообщение было удалено")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
                Spacer()
                Button { dismiss() } label: {
                    Text("Закрыть")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(accent).cornerRadius(14)
                }
                .padding(.horizontal, 24).padding(.bottom, 30)
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Helpers
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}
