import Foundation

// MARK: - Chat
struct Chat: Identifiable, Equatable {
    let id: UUID
    var name: String
    var lastMessage: String
    var time: String
    var unread: Int
    var isOnline: Bool
    var avatarInitials: String
    var isPinned: Bool
    var isMuted: Bool
    var isSecret: Bool
    var scheduledCount: Int
    var pinnedMessage: String?
    var mediaItems: [MediaItem]

    init(id: UUID = UUID(), name: String, lastMessage: String, time: String,
         unread: Int = 0, isOnline: Bool = false, isPinned: Bool = false,
         isMuted: Bool = false, isSecret: Bool = false, scheduledCount: Int = 0,
         pinnedMessage: String? = nil, mediaItems: [MediaItem] = []) {
        self.id = id; self.name = name; self.lastMessage = lastMessage
        self.time = time; self.unread = unread; self.isOnline = isOnline
        self.isPinned = isPinned; self.isMuted = isMuted
        self.isSecret = isSecret; self.scheduledCount = scheduledCount
        self.pinnedMessage = pinnedMessage; self.mediaItems = mediaItems
        let p = name.components(separatedBy: " ")
        self.avatarInitials = p.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

// MARK: - Message
enum MessageStatus { case sending, sent, delivered, read }

enum MessageContent: Equatable {
    case text(String)
    case voice(duration: Int, waveform: [Float])
    case image(name: String)
    case file(name: String, size: String)
}

struct Message: Identifiable, Equatable {
    let id: UUID
    var content: MessageContent
    var isOutgoing: Bool
    var time: String
    var status: MessageStatus
    var reactions: [String: Int]
    var replyTo: ReplyPreview?
    var forwardFrom: String?
    var isScheduled: Bool
    var thread: [Message]

    var text: String {
        if case .text(let t) = content { return t }
        return ""
    }

    init(id: UUID = UUID(), text: String = "", content: MessageContent? = nil,
         isOutgoing: Bool, time: String, status: MessageStatus = .sent,
         reactions: [String: Int] = [:], replyTo: ReplyPreview? = nil,
         forwardFrom: String? = nil, isScheduled: Bool = false, thread: [Message] = []) {
        self.id = id
        self.content = content ?? .text(text)
        self.isOutgoing = isOutgoing; self.time = time; self.status = status
        self.reactions = reactions; self.replyTo = replyTo
        self.forwardFrom = forwardFrom; self.isScheduled = isScheduled
        self.thread = thread
    }
}

struct ReplyPreview: Equatable {
    var senderName: String
    var text: String
}

// MARK: - MediaItem
struct MediaItem: Identifiable, Equatable {
    let id: UUID
    var type: MediaType
    var thumb: String
    var date: String
    enum MediaType { case photo, video, file }
    init(id: UUID = UUID(), type: MediaType = .photo, thumb: String = "", date: String = "") {
        self.id = id; self.type = type; self.thumb = thumb; self.date = date
    }
}

// MARK: - Contact
struct Contact: Identifiable, Equatable {
    let id: UUID
    var name: String
    var username: String
    var isOnline: Bool
    var lastSeen: String
    var isFavorite: Bool
    var hasStory: Bool
    var isPendingRequest: Bool
    var avatarInitials: String

    init(id: UUID = UUID(), name: String, username: String,
         isOnline: Bool = false, lastSeen: String = "",
         isFavorite: Bool = false, hasStory: Bool = false,
         isPendingRequest: Bool = false) {
        self.id = id; self.name = name; self.username = username
        self.isOnline = isOnline; self.lastSeen = lastSeen
        self.isFavorite = isFavorite; self.hasStory = hasStory
        self.isPendingRequest = isPendingRequest
        let p = name.components(separatedBy: " ")
        self.avatarInitials = p.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

// MARK: - Group
struct Group: Identifiable, Equatable {
    let id: UUID
    var name: String
    var lastMessage: String
    var time: String
    var memberCount: Int
    var unread: Int
    var isPublic: Bool
    var avatarInitials: String
    var activeThread: String?
    var members: [GroupMember]

    init(id: UUID = UUID(), name: String, lastMessage: String, time: String,
         memberCount: Int, unread: Int = 0, isPublic: Bool = false,
         activeThread: String? = nil, members: [GroupMember] = []) {
        self.id = id; self.name = name; self.lastMessage = lastMessage
        self.time = time; self.memberCount = memberCount; self.unread = unread
        self.isPublic = isPublic; self.activeThread = activeThread
        self.members = members
        let p = name.components(separatedBy: " ")
        self.avatarInitials = p.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

struct GroupMember: Identifiable, Equatable {
    let id: UUID
    var name: String
    var role: GroupRole
    var avatarInitials: String
    enum GroupRole { case owner, admin, moderator, member }
    init(id: UUID = UUID(), name: String, role: GroupRole = .member) {
        self.id = id; self.name = name; self.role = role
        let p = name.components(separatedBy: " ")
        self.avatarInitials = p.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

// MARK: - Poll
struct Poll: Identifiable {
    let id: UUID
    var question: String
    var options: [(String, Int)]
    var totalVotes: Int
    var userVote: Int?
}

// MARK: - MockData
enum MockData {
    static let chats: [Chat] = [
        Chat(name: "Alex Morgan",  lastMessage: "Встреча завтра в 10:00",
             time: "2м",  unread: 3, isOnline: true,  isPinned: true,
             isSecret: true, pinnedMessage: "Встреча завтра в 10:00",
             mediaItems: [MediaItem(), MediaItem(), MediaItem(), MediaItem()]),
        Chat(name: "Kate Vance",   lastMessage: "Файл отправлен 📎",
             time: "5м",  unread: 0, isOnline: true),
        Chat(name: "Denis S.",     lastMessage: "Посмотри PR",
             time: "1ч",  unread: 2, scheduledCount: 1),
        Chat(name: "Anna K.",      lastMessage: "Спасибо!",       time: "3ч"),
        Chat(name: "iOS Team",     lastMessage: "Build прошёл ✅", time: "вчера", unread: 1, isMuted: true),
        Chat(name: "Max T.",       lastMessage: "Пойдём?",        time: "вчера"),
        Chat(name: "Nika R.",      lastMessage: "Жду твой ответ", time: "2д", unread: 4),
    ]

    static let messages: [Message] = [
        Message(text: "Привет! Как дела с проектом?",     isOutgoing: false, time: "10:01", status: .read),
        Message(text: "Всё идёт по плану, почти готово",  isOutgoing: true,  time: "10:03", status: .read),
        Message(text: "Круто! Когда можно посмотреть?",   isOutgoing: false, time: "10:04",
                status: .read, reactions: ["👍": 1],
                replyTo: ReplyPreview(senderName: "Alex", text: "Всё идёт по плану, почти готово")),
        Message(text: "Завтра к 10 будет готово",         isOutgoing: true,  time: "10:05", status: .read,
                replyTo: ReplyPreview(senderName: "Alex", text: "Когда можно посмотреть?")),
        Message(text: "Отлично, тогда встреча в 10:00",   isOutgoing: false, time: "10:06", status: .read),
        Message(content: .voice(duration: 12, waveform: [0.2,0.5,0.9,0.6,0.3,0.7,0.4,0.8,0.5,0.6,0.2,0.9]),
                isOutgoing: true, time: "10:07", status: .delivered),
        Message(text: "Договорились 👍",                  isOutgoing: true,  time: "10:08", status: .sent),
    ]

    static let contacts: [Contact] = [
        Contact(name: "Alex Morgan", username: "@alexm",  isOnline: true,  isFavorite: true,  hasStory: true),
        Contact(name: "Kate Vance",  username: "@katev",  isOnline: true,  isFavorite: true),
        Contact(name: "Max T.",      username: "@maxt",   isOnline: true,  hasStory: true),
        Contact(name: "Anna K.",     username: "@annak",  isOnline: false, lastSeen: "1ч назад"),
        Contact(name: "Denis S.",    username: "@denisx", isOnline: false, lastSeen: "3ч назад"),
        Contact(name: "Nika R.",     username: "@nikar",  isOnline: false, lastSeen: "вчера"),
        Contact(name: "New User",    username: "@newu",   isPendingRequest: true),
    ]

    static let groups: [Group] = [
        Group(name: "Dev Squad",     lastMessage: "Максим: PR готов",        time: "5м",
              memberCount: 12, unread: 5, activeThread: "Release v2.1",
              members: [
                GroupMember(name: "Alex M.", role: .owner),
                GroupMember(name: "Kate V.", role: .admin),
                GroupMember(name: "Denis S.", role: .moderator),
                GroupMember(name: "Anna K.", role: .member),
              ]),
        Group(name: "Marketing",     lastMessage: "Новый лид",               time: "2ч",  memberCount: 8,  unread: 12),
        Group(name: "iOS Devs RU",   lastMessage: "Кто пробовал Swift 6?",   time: "3ч",  memberCount: 347, isPublic: true),
        Group(name: "Design System", lastMessage: "Обновил токены цветов",   time: "вчера", memberCount: 5),
        Group(name: "MashX Beta",    lastMessage: "Билд 1.0.3 в TestFlight", time: "вчера", memberCount: 23, isPublic: true),
    ]

    static let publicRooms: [Group] = [
        Group(name: "Swift разработка",  lastMessage: "Новые фичи iOS 18",    time: "1м",  memberCount: 1240, isPublic: true),
        Group(name: "UI/UX Дизайн",      lastMessage: "Топ Figma плагины",    time: "15м", memberCount: 876,  isPublic: true),
        Group(name: "Карьера в IT",       lastMessage: "Вакансия iOS Senior",  time: "1ч",  memberCount: 3120, isPublic: true),
        Group(name: "Стартапы СНГ",       lastMessage: "Ищу ко-фаундера",      time: "2ч",  memberCount: 654,  isPublic: true),
    ]

    static let poll = Poll(
        id: UUID(), question: "Когда удобен следующий созвон?",
        options: [("Пн 10:00", 4), ("Вт 15:00", 7), ("Чт 11:00", 3)],
        totalVotes: 14, userVote: nil
    )
}
