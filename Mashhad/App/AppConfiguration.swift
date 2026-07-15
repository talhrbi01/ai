import Foundation

struct AppConfiguration: Sendable {
    let appName: String
    let tmdbAPIKey: String?
    let supabaseURL: URL?
    let supabaseAnonKey: String?

    static func fromBundle(_ bundle: Bundle = .main) -> AppConfiguration {
        let tmdbKey = bundle.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String
        let supabaseURLString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let supabaseURL = supabaseURLString.flatMap(URL.init(string:))
        let supabaseKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        return AppConfiguration(
            appName: (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "مشهد",
            tmdbAPIKey: tmdbKey?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            supabaseURL: supabaseURL,
            supabaseAnonKey: supabaseKey?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
    }

    func imageURL(path: String?, size: String = "w500") -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
