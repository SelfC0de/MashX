import SwiftUI

// MARK: - Локализация без перезапуска
// Использование: Text(L.chats) вместо Text("Чаты")

struct L {
    static var lang: String { SettingsStore.shared.languageIndex == 1 ? "en" : "ru" }
    static func t(_ ru: String, _ en: String) -> String { lang == "en" ? en : ru }

    // Табы
    static var profile:  String { t("Профиль",   "Profile") }
    static var contacts: String { t("Контакты",  "Contacts") }
    static var chats:    String { t("Чаты",      "Chats") }
    static var groups:   String { t("Группы",    "Groups") }
    static var settings: String { t("Настройки", "Settings") }

    // Общие
    static var done:     String { t("Готово",    "Done") }
    static var cancel:   String { t("Отмена",    "Cancel") }
    static var save:     String { t("Сохранить", "Save") }
    static var delete:   String { t("Удалить",   "Delete") }
    static var create:   String { t("Создать",   "Create") }
    static var search:   String { t("Поиск",     "Search") }
    static var online:   String { t("онлайн",    "online") }
    static var offline:  String { t("оффлайн",   "offline") }
    static var error:    String { t("Ошибка",    "Error") }
    static var loading:  String { t("Загрузка",  "Loading") }
    static var noData:   String { t("Нет данных","No data") }

    // Контакты
    static var addContact:    String { t("Добавить контакт",  "Add contact") }
    static var requests:      String { t("Запросы",           "Requests") }
    static var favorites:     String { t("Избранные",         "Favorites") }
    static var blocked:       String { t("Заблокированные",   "Blocked") }

    // Группы
    static var leaveGroup:    String { t("Покинуть группу",   "Leave group") }
    static var deleteGroup:   String { t("Удалить группу",    "Delete group") }
    static var editGroup:     String { t("Редактировать",     "Edit") }
    static var members:       String { t("Участники",         "Members") }
    static var inviteLink:    String { t("Пригласить по ссылке", "Invite by link") }

    // Auth
    static var login:         String { t("Войти",             "Log in") }
    static var register:      String { t("Зарегистрироваться","Sign up") }
    static var logout:        String { t("Выйти из аккаунта", "Log out") }
    static var deleteAccount: String { t("Удалить аккаунт",   "Delete account") }

    // Settings
    static var notifications: String { t("Уведомления",       "Notifications") }
    static var sounds:        String { t("Звуки",             "Sounds") }
    static var privacy:       String { t("Приватность",       "Privacy") }
    static var security:      String { t("Безопасность",      "Security") }
    static var appearance:    String { t("Внешний вид",       "Appearance") }
    static var language:      String { t("Язык",              "Language") }
    static var accentColor:   String { t("Акцентный цвет",    "Accent color") }
    static var fontSize:      String { t("Размер шрифта",     "Font size") }
    static var sessions:      String { t("Активные сессии",   "Active sessions") }
    static var offlineMode:   String { t("Оффлайн режим",     "Offline mode") }
    static var readReceipts:  String { t("Отчёт о прочтении", "Read receipts") }
    static var smartReply:    String { t("Smart Reply AI",    "Smart Reply AI") }
    static var antispam:      String { t("Антиспам",          "Antispam") }
}

// MARK: - LanguageKey для Environment
private struct LanguageKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var languageIndex: Int {
        get { self[LanguageKey.self] }
        set { self[LanguageKey.self] = newValue }
    }
}
