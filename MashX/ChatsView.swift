import SwiftUI

struct APIChat: Decodable, Identifiable {
    let id: String
    let partner_id: String
    let username: String
    let display_name: String
    let avatar_url: String
    let is_online: Bool
    let show_online: Bool
    let last_message_id: String?
    let last_content: String?
    let last_type: String?
    let last_sender_id: String?
    let last_deleted: Bool?
    let last_at: String?
    let unread: Int
    let last_seen_at: String?
}

struct ChatsView: View {
    @State private var chats: [APIChat] = []
    @State private var searchText = ""
    @State private var filterIndex = 0
    @State private var isLoading = false

    @EnvironmentObject private var toast: ToastManager
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var auth: AuthManager
    private let accent = Theme.accentChats
    private let filters = ["Все", "Онлайн", "Непрочит."]

    private var filtered: [APIChat] {
        var list = chats
        switch filterIndex {
        case 1: list = list.filter { $0.is_online && !settings.offlineMode }
        case 2: list = list.filter { $0.unread > 0 }
        default: break
        }
        guard !searchText.isEmpty else { return list }
        let q = searchText.lowercased()
        return list.filter {
            $0.display_name.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            ($0.last_content?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    SearchBar(text: $searchText, placeholder: "Поиск по чатам...", accentColor: accent).padding(.horizontal, 16)
                    filterChips
                    if isLoading && chats.isEmpty {
                        Spacer(); ProgressView().tint(accent); Spacer()
                    } else {
                        chatList
                    }
                }
            }
            .navigationBarHidden(true)
            .task { await loadChats() }
            .refreshable { await loadChats() }
            .onReceive(WebSocketManager.shared.messageReceived) { _ in
                Task { await loadChats() }
            }
        }
    }

    private func loadChats() async {
        isLoading = true; defer { isLoading = false }
        do { chats = try await APIClient.shared.request(url: "\(API.base)/chats") }
        catch {}
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                AnimatedIcon(name: "bubble.left.and.bubble.right.fill", size: 17, color: accent)
                Text("Чаты").font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text).kerning(-0.5)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(filters.indices, id: \.self) { i in
                    FilterChip(label: filters[i], isSelected: filterIndex == i, accent: accent) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { filterIndex = i }
                    }
                }
            }.padding(.horizontal, 16)
        }.padding(.vertical, 8)
    }

    private var chatList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { chat in
                    NavigationLink(destination: ChatDetailView(
                        partnerID: chat.partner_id,
                        partnerName: chat.display_name,
                        partnerAvatar: chat.avatar_url,
                        isPartnerOnline: chat.is_online && chat.show_online
                    )) {
                        ChatRowView(chat: chat, accent: accent, myID: auth.currentUser?.id ?? "")
                    }
                    .buttonStyle(.plain)
                    Divider().background(Theme.sep).padding(.leading, 72)
                }
                if filtered.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32)).foregroundColor(Theme.dim)
                        Text("Нет чатов").font(.system(size: 15)).foregroundColor(Theme.muted)
                        Text("Добавьте контакты и начните переписку")
                            .font(.system(size: 13)).foregroundColor(Theme.dim)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 60)
                }
            }
        }
    }
}

struct ChatRowView: View {
    let chat: APIChat
    let accent: Color
    let myID: String

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(avatarURL: chat.avatar_url,
                           initials: String(chat.display_name.prefix(2)).uppercased(),
                           size: 48, isOnline: chat.is_online && chat.show_online)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(chat.display_name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    Spacer()
                    if let at = chat.last_at {
                        Text(shortTime(at)).font(.system(size: 12)).foregroundColor(Theme.dim)
                    }
                }
                HStack {
                    if chat.last_sender_id == myID {
                        Text("Вы: ").font(.system(size: 13)).foregroundColor(Theme.dim)
                    }
                    Text(chat.last_deleted == true ? "Сообщение удалено" : (chat.last_content ?? ""))
                        .font(.system(size: 13))
                        .foregroundColor(chat.last_deleted == true ? Theme.dim : Theme.muted)
                        .italic(chat.last_deleted == true)
                        .lineLimit(1)
                    Spacer()
                    if chat.unread > 0 {
                        UnreadBadge(count: chat.unread, color: accent)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
    }

    private func shortTime(_ str: String) -> String {
        let formats = ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss"]
        let out = DateFormatter(); out.dateFormat = "HH:mm"
        for fmt in formats {
            let f = DateFormatter(); f.dateFormat = fmt
            if let d = f.date(from: str) { return out.string(from: d) }
        }
        return ""
    }
}
