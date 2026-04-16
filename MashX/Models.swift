import Foundation

// MARK: - Local UI Models (не используют MockData)

// Chat и Contact оставлены как legacy для ChatDetailView
// Постепенно заменятся на API модели

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

    init(id: UUID = UUID(), name: String, username: String = "",
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

    init(id: UUID = UUID(), name: String, lastMessage: String = "", time: String = "",
         memberCount: Int = 0, unread: Int = 0, isPublic: Bool = false,
         activeThread: String? = nil, members: [GroupMember] = []) {
        self.id = id; self.name = name; self.lastMessage = lastMessage
        self.time = time; self.memberCount = memberCount; self.unread = unread
        self.isPublic = isPublic; self.activeThread = activeThread; self.members = members
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

struct Poll: Identifiable {
    let id: UUID
    var question: String
    var options: [(String, Int)]
    var totalVotes: Int
    var userVote: Int?
}

// MockData УДАЛЁН — все данные теперь из API
