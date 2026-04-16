import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @AppStorage("notifications_enabled") var notificationsEnabled: Bool  = true
    @AppStorage("sound_enabled")         var soundEnabled: Bool          = true
    @AppStorage("show_online_status")    var showOnlineStatus: Bool      = true
    @AppStorage("send_read_receipts")    var sendReadReceipts: Bool      = true
    @AppStorage("offline_mode")          var offlineMode: Bool           = false
    @AppStorage("username")              var username: String            = ""
    @AppStorage("bio")                   var bio: String                 = ""
    @AppStorage("accent_index")          var accentIndex: Int            = 0
    @AppStorage("font_size_index")       var fontSizeIndex: Int          = 1
    @AppStorage("auto_delete_index")     var autoDeleteIndex: Int        = 0
    @AppStorage("e2e_enabled")           var e2eEnabled: Bool            = true
    @AppStorage("language_index")        var languageIndex: Int          = 0
    @AppStorage("proximity_ping")        var proximityPing: Bool         = false
    @AppStorage("smart_reply")           var smartReply: Bool            = true
    @AppStorage("antispam")              var antispam: Bool              = true

    private init() {}
}
