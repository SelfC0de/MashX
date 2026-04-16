import SwiftUI

struct L {
    // Читаем напрямую из UserDefaults — без @MainActor
    static var lang: String {
        UserDefaults.standard.integer(forKey: "language_index") == 1 ? "en" : "ru"
    }
    static func t(_ ru: String, _ en: String) -> String { lang == "en" ? en : ru }

    static var profile:  String { t("Профиль",   "Profile") }
    static var contacts: String { t("Контакты",  "Contacts") }
    static var chats:    String { t("Чаты",      "Chats") }
    static var groups:   String { t("Группы",    "Groups") }
    static var settings: String { t("Настройки", "Settings") }

    static var done:     String { t("Готово",    "Done") }
    static var cancel:   String { t("Отмена",    "Cancel") }
    static var save:     String { t("Сохранить", "Save") }
    static var delete:   String { t("Удалить",   "Delete") }
    static var create:   String { t("Создать",   "Create") }
    static var search:   String { t("Поиск",     "Search") }
    static var online:   String { t("онлайн",    "online") }
    static var offline:  String { t("оффлайн",   "offline") }
    static var error:    String { t("Ошибка",    "Error") }
    static var noData:   String { t("Нет данных","No data") }

    static var addContact:    String { t("Добавить контакт",     "Add contact") }
    static var favorites:     String { t("Избранные",            "Favorites") }
    static var leaveGroup:    String { t("Покинуть группу",      "Leave group") }
    static var deleteGroup:   String { t("Удалить группу",       "Delete group") }
    static var editGroup:     String { t("Редактировать",        "Edit") }
    static var members:       String { t("Участники",            "Members") }
    static var inviteLink:    String { t("Пригласить по ссылке", "Invite by link") }
    static var login:         String { t("Войти",                "Log in") }
    static var logout:        String { t("Выйти из аккаунта",    "Log out") }
    static var notifications: String { t("Уведомления",          "Notifications") }
    static var sounds:        String { t("Звуки",                "Sounds") }
    static var privacy:       String { t("Приватность",          "Privacy") }
    static var appearance:    String { t("Внешний вид",          "Appearance") }
    static var language:      String { t("Язык",                 "Language") }
    static var accentColor:   String { t("Акцентный цвет",       "Accent color") }
    static var fontSize:      String { t("Размер шрифта",        "Font size") }
    static var sessions:      String { t("Активные сессии",      "Active sessions") }
    static var offlineMode:   String { t("Оффлайн режим",        "Offline mode") }
    static var readReceipts:  String { t("Отчёт о прочтении",    "Read receipts") }
    static var smartReply:    String { t("Smart Reply AI",       "Smart Reply AI") }
    static var antispam:      String { t("Антиспам",             "Antispam") }
}
