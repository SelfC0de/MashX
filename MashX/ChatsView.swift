import SwiftUI

struct ChatsView: View {
    @State private var chats = MockData.chats
    @State private var searchText = ""
    @State private var filterIndex = 0
    @State private var searchDate: Date? = nil
    @State private var showDatePicker = false
    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentChats
    private let filters = ["Все", "Непрочит.", "Личные", "Группы"]

    private var filtered: [Chat] {
        var list = chats
        switch filterIndex {
        case 1: list = list.filter { $0.unread > 0 }
        case 2: list = list.filter { !$0.name.contains("Squad") && !$0.name.contains("Team") && !$0.name.contains("iOS") }
        case 3: list = list.filter { $0.name.contains("Squad") || $0.name.contains("Team") || $0.name.contains("iOS") }
        default: break
        }
        guard !searchText.isEmpty else { return list }
        let q = searchText.lowercased()
        return list.filter {
            $0.name.lowercased().contains(q) ||
            $0.lastMessage.lowercased().contains(q) ||
            $0.time.lowercased().contains(q)
        }
    }

    private var pinned: [Chat] { filtered.filter { $0.isPinned } }
    private var rest:   [Chat] { filtered.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    searchBar
                    filterChips
                    chatList
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: Header
    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                AnimatedIcon(name: "bubble.left.and.bubble.right.fill", size: 17, color: accent)
                Text("Чаты")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.text).kerning(-0.5)
            }
            Spacer()
            HStack(spacing: 8) {
                Button { showDatePicker.toggle() } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(searchDate != nil ? accent : Theme.muted)
                        .frame(width: 34, height: 34).background((searchDate != nil ? accent : Theme.card).opacity(searchDate != nil ? 0.15 : 1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                }
                Button { toast.show("Новый чат", style: .info, icon: "square.and.pencil") } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
    }

    // MARK: Search
    private var searchBar: some View {
        VStack(spacing: 6) {
            SearchBar(text: $searchText, placeholder: "Поиск по чатам...", accentColor: accent)
                .padding(.horizontal, 16)
            if showDatePicker {
                DatePicker("Дата", selection: Binding(
                    get: { searchDate ?? Date() },
                    set: { searchDate = $0; showDatePicker = false }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(accent)
                .padding(.horizontal, 16)
                .background(Theme.card).cornerRadius(12)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if let d = searchDate {
                HStack {
                    Image(systemName: "calendar").font(.system(size: 11)).foregroundColor(accent)
                    Text("Фильтр: \(d.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12)).foregroundColor(accent)
                    Spacer()
                    Button { withAnimation { searchDate = nil } } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 13)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDatePicker)
        .animation(.easeInOut(duration: 0.2), value: searchDate != nil)
    }

    // MARK: Filters
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
        .padding(.bottom, 8)
    }

    // MARK: List
    private var chatList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if !pinned.isEmpty {
                    SectionHeader(title: "Закреплённые", accentColor: accent)
                    ForEach(pinned) { c in chatRow(c) }
                }
                if !rest.isEmpty {
                    if !pinned.isEmpty { SectionHeader(title: "Все чаты", accentColor: accent) }
                    ForEach(rest) { c in chatRow(c) }
                }
                if filtered.isEmpty {
                    emptyState
                }
            }
        }
    }

    @ViewBuilder
    private func chatRow(_ chat: Chat) -> some View {
        NavigationLink(destination: ChatDetailView(chat: chat)) {
            ChatRow(chat: chat, accent: accent)
        }
        .buttonStyle(.plain)
        Divider().background(Theme.sep).padding(.leading, 72)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32)).foregroundColor(Theme.dim)
            Text("Ничего не найдено")
                .font(.system(size: 15)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

// MARK: - ChatRow
struct ChatRow: View {
    let chat: Chat
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: chat.avatarInitials, size: 48, isOnline: chat.isOnline)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if chat.isPinned {
                        Image(systemName: "pin.fill").font(.system(size: 9)).foregroundColor(accent)
                    }
                    if chat.isSecret {
                        Image(systemName: "lock.fill").font(.system(size: 9)).foregroundColor(Theme.accentGroups)
                    }
                    Text(chat.name)
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    Spacer()
                    if chat.isMuted {
                        Image(systemName: "bell.slash.fill").font(.system(size: 10)).foregroundColor(Theme.dim)
                    }
                    Text(chat.time).font(.system(size: 12)).foregroundColor(Theme.dim)
                }
                HStack {
                    Text(chat.lastMessage)
                        .font(.system(size: 13)).foregroundColor(Theme.muted).lineLimit(1)
                    Spacer()
                    if chat.scheduledCount > 0 {
                        Image(systemName: "clock.fill").font(.system(size: 10)).foregroundColor(accent)
                    }
                    UnreadBadge(count: chat.unread, color: chat.isMuted ? Theme.dim : accent)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
    }
}
