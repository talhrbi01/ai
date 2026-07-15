import XCTest
@testable import Mashhad

final class MashhadTests: XCTestCase {
    func testPreviewServiceReturnsPreviewData() async throws {
        let service = PreviewTMDBService()
        let results = try await service.search(query: "عينة")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.kind, .series)
    }

    func testWatchlistEntryHasStableUniqueIdentifier() {
        let media = PreviewTMDBService.samples[0]
        let entry = WatchlistEntry(media: media)
        XCTAssertEqual(entry.id, "series-1")
        XCTAssertEqual(entry.status, .planToWatch)
    }

    func testImageURLUsesTMDBPath() {
        let configuration = AppConfiguration(appName: "Mashhad", tmdbAPIKey: nil, supabaseURL: nil, supabaseAnonKey: nil)
        XCTAssertEqual(configuration.imageURL(path: "/poster.jpg")?.absoluteString, "https://image.tmdb.org/t/p/w500/poster.jpg")
    }

    func testWatchProgressFiltersInvalidEpisodes() {
        let progress = WatchProgressCalculator.progress(totalEpisodes: 4, watchedEpisodeNumbers: [1, 2, 0, 8])
        XCTAssertEqual(progress.watchedEpisodes, 2)
        XCTAssertEqual(progress.fraction, 0.5)
        XCTAssertEqual(WatchProgressCalculator.nextUnwatchedEpisode(totalEpisodes: 4, watchedEpisodeNumbers: [1, 2]), 3)
    }

    func testSpoilerProtectionHidesUnwatchedLocations() {
        let watched = EpisodeCoordinate(season: 1, episode: 2)
        XCTAssertFalse(SpoilerProtection.shouldHide(
            spoilerAt: EpisodeCoordinate(season: 1, episode: 2),
            watchedThrough: watched,
            explicitlyRevealed: false
        ))
        XCTAssertTrue(SpoilerProtection.shouldHide(
            spoilerAt: EpisodeCoordinate(season: 1, episode: 3),
            watchedThrough: watched,
            explicitlyRevealed: false
        ))
        XCTAssertFalse(SpoilerProtection.shouldHide(
            spoilerAt: EpisodeCoordinate(season: 2, episode: 1),
            watchedThrough: watched,
            explicitlyRevealed: true
        ))
    }

    func testPreviewServiceReturnsEpisodeData() async throws {
        let media = PreviewTMDBService.samples[0]
        let episodes = try await PreviewTMDBService().episodes(for: media, seasonNumber: 1)
        XCTAssertEqual(episodes.first?.id, 101)
        XCTAssertEqual(episodes.first?.seasonNumber, 1)
    }

    func testEpisodeProgressHasStableIdentifier() {
        let progress = EpisodeProgress(mediaID: 42, seasonNumber: 2, episodeNumber: 7, watchedAt: .now)
        XCTAssertEqual(progress.id, "42-s2-e7")
        XCTAssertTrue(progress.isWatched)
    }
}
