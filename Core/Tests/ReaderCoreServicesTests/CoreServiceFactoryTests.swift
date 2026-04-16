import Foundation
import XCTest
import ReaderCoreModels
import ReaderCoreProtocols
import ReaderCoreServices

// MARK: - CoreServiceFactoryTests

/// Integration-level tests for CoreServiceFactory.
///
/// Each test verifies the complete network → parse pipeline through the public
/// factory surface.  No internal type (NetworkPolicyLayer, NonJSParserEngine) is
/// referenced — only the protocol contracts and the factory itself.
final class CoreServiceFactoryTests: XCTestCase {

    // ─────────────────────────────────────────────
    // MARK: Fixture source (matches sample_001.json)
    // ─────────────────────────────────────────────

    private let fixtureSource = BookSource(
        bookSourceName: "Test-Fixture-Source",
        bookSourceUrl:  "http://fixture.test",
        searchUrl:      "http://fixture.test/search?q={{key}}",
        ruleSearch:     "css:.item",
        ruleToc:        "css:.chapter",
        ruleContent:    "css:.content",
        enabled:        true
    )

    // ─────────────────────────────────────────────
    // MARK: Search
    // ─────────────────────────────────────────────

    func testSearchServiceReturnsExpectedItems() async throws {
        let html = """
        <html><body>
        <div class="item">天道图书馆|http://fixture.test/book/1|佚名</div>
        <div class="item">星辰大海|http://fixture.test/book/2|无名氏</div>
        </body></html>
        """
        let services = makeServices(response: html)

        let results = try await services.search.search(
            source: fixtureSource,
            query:  SearchQuery(keyword: "天道")
        )

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].title,     "天道图书馆")
        XCTAssertEqual(results[0].detailURL, "http://fixture.test/book/1")
        XCTAssertEqual(results[0].author,    "佚名")
        XCTAssertEqual(results[1].title,     "星辰大海")
    }

    func testSearchServiceReturnsEmptyForNoMatchingElements() async throws {
        let html = "<html><body><p>nothing here</p></body></html>"
        let services = makeServices(response: html)

        let results = try await services.search.search(
            source: fixtureSource,
            query:  SearchQuery(keyword: "q")
        )

        XCTAssertTrue(results.isEmpty)
    }

    // ─────────────────────────────────────────────
    // MARK: TOC
    // ─────────────────────────────────────────────

    func testTOCServiceReturnsExpectedChapters() async throws {
        let html = """
        <html><body>
        <div class="chapter">序章：开始|http://fixture.test/chapter/0</div>
        <div class="chapter">第一章：觉醒|http://fixture.test/chapter/1</div>
        </body></html>
        """
        let services = makeServices(response: html)

        let chapters = try await services.toc.fetchTOC(
            source:    fixtureSource,
            detailURL: "http://fixture.test/book/1"
        )

        XCTAssertEqual(chapters.count, 2)
        XCTAssertEqual(chapters[0].title,      "序章：开始")
        XCTAssertEqual(chapters[0].chapterURL, "http://fixture.test/chapter/0")
        XCTAssertEqual(chapters[1].title,      "第一章：觉醒")
    }

    // ─────────────────────────────────────────────
    // MARK: Content
    // ─────────────────────────────────────────────

    func testContentServiceReturnsPageContent() async throws {
        let expected = "夜已深，李珑独自伫立于图书馆最高处的露台上，俯瞰着整座城市星星点点的灯火。"
        let html = """
        <html><body>
        <div class="content">\(expected)</div>
        </body></html>
        """
        let services = makeServices(response: html)

        let page = try await services.content.fetchContent(
            source:     fixtureSource,
            chapterURL: "http://fixture.test/chapter/0"
        )

        XCTAssertEqual(page.content, expected)
    }

    func testContentServiceReturnsEmptyStringForNoMatchingElement() async throws {
        let html = "<html><body><p>no content selector</p></body></html>"
        let services = makeServices(response: html)

        let page = try await services.content.fetchContent(
            source:     fixtureSource,
            chapterURL: "http://fixture.test/chapter/0"
        )

        XCTAssertTrue(page.content.isEmpty)
    }

    // ─────────────────────────────────────────────
    // MARK: Factory contract
    // ─────────────────────────────────────────────

    /// Verify that factory products conform to the expected protocol types.
    func testFactoryProductsConformToProtocols() async throws {
        let mock     = FixtureMockHTTPClient(responseBody: "<html/>")
        let deps     = CoreAdapterDependencies(http: mock)
        let services = CoreServiceFactory.make(dependencies: deps)

        XCTAssertTrue((services.search  as AnyObject) is (any SearchService))
        XCTAssertTrue((services.toc     as AnyObject) is (any TOCService))
        XCTAssertTrue((services.content as AnyObject) is (any ContentService))
    }

    // ─────────────────────────────────────────────
    // MARK: Full loop integration
    // ─────────────────────────────────────────────

    /// Search → pick first result URL → TOC → pick first chapter → Content.
    /// Each step uses a fresh response queue so URLs flow naturally.
    func testFullSearchTOCContentLoop() async throws {
        let searchHTML = """
        <html><body>
        <div class="item">天道图书馆|http://fixture.test/book/1|佚名</div>
        </body></html>
        """
        let tocHTML = """
        <html><body>
        <div class="chapter">序章：开始|http://fixture.test/chapter/0</div>
        </body></html>
        """
        let contentHTML = """
        <html><body>
        <div class="content">这是序章的正文内容。</div>
        </body></html>
        """

        let mock = FixtureQueuedMockHTTPClient()
        await mock.enqueue(searchHTML)
        await mock.enqueue(tocHTML)
        await mock.enqueue(contentHTML)

        let deps     = CoreAdapterDependencies(http: mock)
        let services = CoreServiceFactory.make(dependencies: deps)

        // Step 1 — search
        let results = try await services.search.search(
            source: fixtureSource,
            query:  SearchQuery(keyword: "天道")
        )
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].title, "天道图书馆")

        // Step 2 — toc
        let chapters = try await services.toc.fetchTOC(
            source:    fixtureSource,
            detailURL: results[0].detailURL
        )
        XCTAssertEqual(chapters.count, 1)
        XCTAssertEqual(chapters[0].title, "序章：开始")

        // Step 3 — content
        let page = try await services.content.fetchContent(
            source:     fixtureSource,
            chapterURL: chapters[0].chapterURL
        )
        XCTAssertEqual(page.content, "这是序章的正文内容。")
    }
}

// ─────────────────────────────────────────────
// MARK: Test helpers
// ─────────────────────────────────────────────

/// Returns a `CoreServices` bundle wired through a single-response mock.
private func makeServices(response body: String) -> CoreServices {
    let mock = FixtureMockHTTPClient(responseBody: body)
    let deps = CoreAdapterDependencies(http: mock)
    return CoreServiceFactory.make(dependencies: deps)
}

// MARK: FixtureMockHTTPClient

/// Single-response mock: every request returns the same pre-canned body.
private actor FixtureMockHTTPClient: HTTPAdapterProtocol {
    private let body: String
    init(responseBody: String) { self.body = responseBody }
    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        HTTPResponse(statusCode: 200,
                     headers: ["Content-Type": "text/html"],
                     data: Data(body.utf8))
    }
}

// MARK: FixtureQueuedMockHTTPClient

/// Queue-based mock: each call to `send` dequeues the next pre-canned response.
private actor FixtureQueuedMockHTTPClient: HTTPAdapterProtocol {
    private var queue: [String] = []
    func enqueue(_ body: String) { queue.append(body) }
    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let body = queue.isEmpty ? "" : queue.removeFirst()
        return HTTPResponse(statusCode: 200,
                            headers: ["Content-Type": "text/html"],
                            data: Data(body.utf8))
    }
}
