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
}
