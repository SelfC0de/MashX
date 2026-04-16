import SwiftUI

// Чаты пока основаны на контактах из API — реальный чат требует WebSocket/Tinode
// Показываем список контактов как "чаты", без фейковых данных
struct ChatsView: View {
    @State private var contacts: [APIContact] = []
    @State private var searchText = ""
    @State private var filterIndex = 0
    @State private var isLoading = false

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentChats
    private let filters = ["Все", "Онлайн", "Избранные"]

    private var filtered: [APIContact] {
        let accepted = contacts.filter { $0.status == "accepted" }
        var list: [APIContact]
        switch filterIndex {
        case 1: list = accepted.filter { ($0.user?.is_online ?? false) && !settings.offlineMode }
        case 2: list = accepted.filter { $0.is_favorite }
        default: list = accepted
        }
        guard !searchText.isEmpty else { return list }
        let q = searchText.lowercased()
        return list.filter {
            ($0.user?.display_name.lowercased().contains(q) ?? false) ||
            ($0.user?.username.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    SearchBar(text: $searchText, placeholder: "Поиск по чатам...", accentColor: accent)
                        .padding(.horizontal, 16)
                    filterChips
                    if isLoading && contacts.isEmpty {
                        Spacer(); ProgressView().tint(accent); Spacer()
                    } else {
                        chatList
                    }
                }
            }
            .navigationBarHidden(true)
            .task { await loadContacts() }
            .refreshable { await loadContacts() }
        }
    }

    private func loadContacts() async {
        isLoading = true; defer { isLoading = false }
        do { contacts = try await APIClient.shared.request(url: API.Contacts.list) }
        catch { toast.show("Ошибка загрузки", style: .error) }
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                AnimatedIcon(name: "bubble.left.and.bubble.right.fill", size: 17, color: accent)
                Text("Чаты").font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text).kerning(-0.5)
            }
            Spacer()
            Button { toast.show("Новый чат", style: .info, icon: "square.and.pencil") } label: {
                Image(systemName: "square.and.pencil").font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                    .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
            }
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
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private var chatList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { c in
                    let name = c.user?.display_name ?? c.user?.username ?? "User"
                    let initials = String(name.prefix(2)).uppercased()
                    let isOnline = (c.user?.is_online ?? false) && !settings.offlineMode

                    HStack(spacing: 12) {
                        AvatarView(initials: initials, size: 48, isOnline: isOnline)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                if c.is_favorite {
                                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(accent)
                                }
                                Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                                Spacer()
                            }
                            Text(isOnline ? "онлайн" : "@\(c.user?.username ?? "")")
                                .font(.system(size: 13)).foregroundColor(isOnline ? accent : Theme.muted).lineLimit(1)
                        }
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(Theme.dim)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())

                    Divider().background(Theme.sep).padding(.leading, 72)
                }

                if filtered.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32)).foregroundColor(Theme.dim)
                        Text(contacts.isEmpty ? "Нет контактов для чата" : "Ничего не найдено")
                            .font(.system(size: 15)).foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 60)
                }
            }
        }
    }
}
