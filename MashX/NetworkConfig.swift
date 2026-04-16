import Foundation

enum API {
    static let base = "https://metallurgfk.ru/api"

    enum Auth {
        static let register    = "\(base)/auth/register"
        static let login       = "\(base)/auth/login"
        static let refresh     = "\(base)/auth/refresh"
        static let recover     = "\(base)/auth/recover"
        static let logout      = "\(base)/auth/logout"
        static let logoutAll   = "\(base)/auth/logout-all"
        static let sessions    = "\(base)/auth/sessions"
    }

    enum User {
        static let me          = "\(base)/me"
        static let avatar      = "\(base)/me/avatar"
        static let search      = "\(base)/users/search"
        static func profile(_ username: String) -> String { "\(base)/users/\(username)" }
    }

    enum Contacts {
        static let list        = "\(base)/contacts"
        static let pending     = "\(base)/contacts/pending"
        static func accept(_ id: String) -> String { "\(base)/contacts/\(id)/accept" }
        static func reject(_ id: String) -> String { "\(base)/contacts/\(id)/reject" }
        static func block(_ id: String)  -> String { "\(base)/contacts/\(id)/block" }
        static func favorite(_ id: String) -> String { "\(base)/contacts/\(id)/favorite" }
        static func remove(_ id: String) -> String { "\(base)/contacts/\(id)" }
    }

    enum Groups {
        static let list        = "\(base)/groups"
        static let pub         = "\(base)/groups/public"
        static func get(_ id: String)     -> String { "\(base)/groups/\(id)" }
        static func join(_ id: String)    -> String { "\(base)/groups/\(id)/join" }
        static func leave(_ id: String)   -> String { "\(base)/groups/\(id)/leave" }
        static func members(_ id: String) -> String { "\(base)/groups/\(id)/members" }
        static func polls(_ id: String)   -> String { "\(base)/groups/\(id)/polls" }
    }
}
