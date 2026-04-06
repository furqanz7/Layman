import Foundation

struct AppConfig {
    let supabaseURL: URL?
    let supabaseAnonKey: String
    let newsAPIKey: String
    let aiAPIKey: String
    let aiBaseURL: URL?
    let aiModel: String
    let aiProvider: AIProvider

    static let shared = AppConfig.load()

    static func load() -> AppConfig {
        let bundle = Bundle.main
        let dictionary = bundle.url(forResource: "Secrets", withExtension: "plist")
            .flatMap { NSDictionary(contentsOf: $0) as? [String: Any] } ?? [:]

        func string(_ key: String, fallback: String = "") -> String {
            dictionary[key] as? String ?? fallback
        }

        return AppConfig(
            supabaseURL: URL(string: string("SUPABASE_URL")),
            supabaseAnonKey: string("SUPABASE_ANON_KEY"),
            newsAPIKey: string("NEWSDATA_API_KEY"),
            aiAPIKey: string("AI_API_KEY"),
            aiBaseURL: URL(string: string("AI_BASE_URL", fallback: "https://api.groq.com/openai/v1")),
            aiModel: string("AI_MODEL", fallback: "llama-3.3-70b-versatile"),
            aiProvider: AIProvider(rawValue: string("AI_PROVIDER", fallback: "openai_compatible")) ?? .openAICompatible
        )
    }

    var hasSupabase: Bool {
        supabaseURL != nil && !supabaseAnonKey.isEmpty
    }

    var hasNewsAPI: Bool {
        !newsAPIKey.isEmpty
    }

    var hasAI: Bool {
        aiBaseURL != nil && !aiAPIKey.isEmpty
    }
}

enum AIProvider: String {
    case openAICompatible = "openai_compatible"
    case gemini
}
