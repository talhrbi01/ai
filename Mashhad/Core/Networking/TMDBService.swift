import Foundation

protocol TMDBServiceProtocol: Sendable {
    func trending() async throws -> [MediaSummary]
    func search(query: String) async throws -> [MediaSummary]
    func details(for media: MediaSummary) async throws -> MediaDetails
    func episodes(for media: MediaSummary, seasonNumber: Int) async throws -> [EpisodeSummary]
}

enum TMDBError: LocalizedError, Sendable {
    case missingAPIKey
    case unsupportedMedia

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "أضف مفتاح TMDB إلى إعدادات التشغيل لجلب المحتوى."
        case .unsupportedMedia: return "نوع العمل غير مدعوم من المصدر."
        }
    }
}

final class TMDBService: TMDBServiceProtocol, @unchecked Sendable {
    private let apiKey: String?
    private let client: APIClient
    private let baseURL: URL

    init(apiKey: String?, client: APIClient = APIClient()) {
        self.apiKey = apiKey
        self.client = client
        guard let baseURL = URL(string: "https://api.themoviedb.org/3") else {
            fatalError("TMDB base URL is a compile-time constant and must be valid")
        }
        self.baseURL = baseURL
    }

    func trending() async throws -> [MediaSummary] {
        let response: TMDBListResponse = try await request(path: "trending/all/day")
        return response.results.compactMap { $0.summary }
    }

    func search(query: String) async throws -> [MediaSummary] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let response: TMDBListResponse = try await request(
            path: "search/multi",
            queryItems: [URLQueryItem(name: "query", value: query)]
        )
        return response.results.compactMap { $0.summary }
    }

    func details(for media: MediaSummary) async throws -> MediaDetails {
        let path: String
        switch media.kind {
        case .movie: path = "movie/\(media.id)"
        case .series: path = "tv/\(media.id)"
        }

        let dto: TMDBDetailsDTO = try await request(
            path: path,
            queryItems: [URLQueryItem(name: "append_to_response", value: "credits")]
        )
        return dto.details(fallback: media)
    }

    func episodes(for media: MediaSummary, seasonNumber: Int) async throws -> [EpisodeSummary] {
        guard media.kind == .series else { throw TMDBError.unsupportedMedia }
        let response: TMBDEpisodesResponse = try await request(path: "tv/\(media.id)/season/\(seasonNumber)")
        return response.episodes.map { $0.summary }
    }

    private func request<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard let apiKey, !apiKey.isEmpty else { throw TMDBError.missingAPIKey }
        return try await client.get(
            baseURL: baseURL,
            path: path,
            queryItems: queryItems + [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "language", value: "ar-SA"),
                URLQueryItem(name: "region", value: "SA")
            ]
        )
    }
}

struct PreviewTMDBService: TMDBServiceProtocol {
    func trending() async throws -> [MediaSummary] { Self.samples }
    func search(query: String) async throws -> [MediaSummary] {
        Self.samples.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    func details(for media: MediaSummary) async throws -> MediaDetails {
        MediaDetails(summary: media, cast: [], seasons: [])
    }

    func episodes(for media: MediaSummary, seasonNumber: Int) async throws -> [EpisodeSummary] {
        guard media.kind == .series else { throw TMDBError.unsupportedMedia }
        return [
            EpisodeSummary(
                id: 101,
                seasonNumber: seasonNumber,
                episodeNumber: 1,
                name: "حلقة تجريبية",
                overview: "بيانات مخصصة للمعاينة والاختبارات فقط.",
                stillPath: nil,
                airDate: Date()
            )
        ]
    }

    static let samples = [
        MediaSummary(
            id: 1, kind: .series, title: "عينة للمعاينة", originalTitle: "Preview Sample",
            overview: "بيانات مخصصة للمعاينات والاختبارات فقط.", posterPath: nil, backdropPath: nil,
            releaseDate: Date(), voteAverage: 8.2, genreNames: ["دراما"], numberOfSeasons: 2
        )
    ]
}

private struct TMDBListResponse: Decodable {
    let results: [TMDBMediaDTO]
}

private struct TMBDEpisodesResponse: Decodable {
    let episodes: [TMDBEpisodeDTO]
}

private struct TMDBMediaDTO: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let originalTitle: String?
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case originalTitle = "original_title"
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
    }

    var summary: MediaSummary? {
        let kind: MediaKind
        if mediaType == "movie" || (title != nil && name == nil) {
            kind = .movie
        } else if mediaType == "tv" || name != nil {
            kind = .series
        } else {
            return nil
        }

        return MediaSummary(
            id: id,
            kind: kind,
            title: title ?? name ?? "",
            originalTitle: originalTitle ?? originalName,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: TMDBDate.parse(releaseDate ?? firstAirDate),
            voteAverage: voteAverage ?? 0,
            genreNames: [],
            numberOfSeasons: nil
        )
    }
}

private struct TMDBDetailsDTO: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let originalTitle: String?
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let numberOfSeasons: Int?
    let genres: [TMDBGenreDTO]?
    let seasons: [TMDBSeasonDTO]?
    let credits: TMDBCreditsDTO?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview, genres, seasons, credits
        case originalTitle = "original_title"
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case numberOfSeasons = "number_of_seasons"
    }

    func details(fallback: MediaSummary) -> MediaDetails {
        let kind: MediaKind = name == nil ? .movie : .series
        let summary = MediaSummary(
            id: id,
            kind: kind,
            title: title ?? name ?? fallback.title,
            originalTitle: originalTitle ?? originalName ?? fallback.originalTitle,
            overview: overview ?? fallback.overview,
            posterPath: posterPath ?? fallback.posterPath,
            backdropPath: backdropPath ?? fallback.backdropPath,
            releaseDate: TMDBDate.parse(releaseDate ?? firstAirDate) ?? fallback.releaseDate,
            voteAverage: voteAverage ?? fallback.voteAverage,
            genreNames: genres?.map(\.name) ?? fallback.genreNames,
            numberOfSeasons: numberOfSeasons ?? fallback.numberOfSeasons
        )
        return MediaDetails(
            summary: summary,
            cast: credits?.cast?.map { CastMember(id: $0.id, name: $0.name, character: $0.character, profilePath: $0.profilePath) } ?? [],
            seasons: seasons?.map { SeasonSummary(id: $0.id, seasonNumber: $0.seasonNumber, name: $0.name, episodeCount: $0.episodeCount) } ?? []
        )
    }
}

private struct TMDBGenreDTO: Decodable { let name: String }

private struct TMDBSeasonDTO: Decodable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
    }
}

private struct TMDBEpisodeDTO: Decodable {
    let id: Int
    let name: String
    let overview: String?
    let stillPath: String?
    let airDate: String?
    let episodeNumber: Int
    let seasonNumber: Int

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case stillPath = "still_path"
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
    }

    var summary: EpisodeSummary {
        EpisodeSummary(
            id: id,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            name: name,
            overview: overview ?? "",
            stillPath: stillPath,
            airDate: TMDBDate.parse(airDate)
        )
    }
}

private struct TMDBCreditsDTO: Decodable {
    let cast: [TMDBCastDTO]?
}

private struct TMDBCastDTO: Decodable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
}

private enum TMDBDate {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}
