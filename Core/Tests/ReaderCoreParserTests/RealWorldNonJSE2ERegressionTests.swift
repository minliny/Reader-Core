import XCTest
@testable import ReaderCoreParser
import ReaderCoreModels

final class RealWorldNonJSE2ERegressionTests: XCTestCase {
    private var engine: NonJSParserEngine!

    override func setUp() {
        super.setUp()
        engine = NonJSParserEngine()
    }

    private func loadBookSource(for caseId: String) -> BookSource {
        let url = URL(fileURLWithPath: "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/\(caseId)/booksource.json")
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try! decoder.decode(BookSource.self, from: data)
    }

    private func loadFixture(for caseId: String, named: String) -> Data {
        let url = URL(fileURLWithPath: "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/\(caseId)/fixtures/\(named).html")
        return try! Data(contentsOf: url)
    }

    private func loadExpectedSearch(for caseId: String) -> [[String: String]] {
        let url = URL(fileURLWithPath: "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/\(caseId)/expected/search_result.json")
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([[String: String]].self, from: data)
    }

    private func loadExpectedDetail(for caseId: String) -> [String: String] {
        let url = URL(fileURLWithPath: "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/\(caseId)/expected/detail_result.json")
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([String: String].self, from: data)
    }

    private func loadExpectedTOC(for caseId: String) -> [[String: String]] {
        let url = URL(fileURLWithPath: "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/\(caseId)/expected/toc_result.json")
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([[String: String]].self, from: data)
    }

    private func loadExpectedContent(for caseId: String) -> [String: String] {
        let url = URL(fileURLWithPath: "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/\(caseId)/expected/content_result.json")
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([String: String].self, from: data)
    }

    func testCase001FullPipeline() throws {
        print("\n=== Testing Case 001 Full Pipeline ===")

        let source = loadBookSource(for: "case_001")

        // Step 1: Search
        print("Step 1: Search")
        let searchData = loadFixture(for: "case_001", named: "search")
        let searchResult = try engine.parseSearchResponse(searchData, source: source, query: SearchQuery(keyword: "test"))
        let expectedSearch = loadExpectedSearch(for: "case_001")

        XCTAssertEqual(searchResult.count, expectedSearch.count, "Search result count mismatch")
        for (index, item) in searchResult.enumerated() {
            XCTAssertEqual(item.title, expectedSearch[index]["title"], "Title mismatch at index \(index)")
            XCTAssertEqual(item.detailURL, expectedSearch[index]["detailURL"], "DetailURL mismatch at index \(index)")
            XCTAssertEqual(item.author, expectedSearch[index]["author"], "Author mismatch at index \(index)")
        }
        print("✓ Search passed")
        print("  - Found \(searchResult.count) books")
        print("  - First book: \(searchResult.first?.title ?? "N/A") at \(searchResult.first?.detailURL ?? "N/A")")

        // Step 2: Detail - using search result's URL
        print("Step 2: Detail (using search result URL)")
        let detailData = loadFixture(for: "case_001", named: "detail")
        let firstBookURL = searchResult.first?.detailURL ?? ""
        let bookInfo = try engine.parseBookInfoResponse(detailData, source: source, detailURL: firstBookURL)
        let expectedDetail = loadExpectedDetail(for: "case_001")

        XCTAssertEqual(bookInfo.bookName, expectedDetail["bookName"], "BookName mismatch")
        XCTAssertEqual(bookInfo.author, expectedDetail["author"], "Author mismatch")
        XCTAssertEqual(bookInfo.coverURL, expectedDetail["coverURL"], "CoverURL mismatch")
        XCTAssertEqual(bookInfo.intro, expectedDetail["intro"], "Intro mismatch")
        XCTAssertEqual(bookInfo.tocURL, expectedDetail["tocURL"], "TOCURL mismatch")
        print("✓ Detail passed")
        print("  - Book name: \(bookInfo.bookName)")
        print("  - Author: \(bookInfo.author)")
        print("  - TOC URL: \(bookInfo.tocURL)")

        // Step 3: TOC - using detail result's tocURL
        print("Step 3: TOC (using detail result's tocURL)")
        let tocData = loadFixture(for: "case_001", named: "toc")
        let tocURL = bookInfo.tocURL
        let tocResult = try engine.parseTOCResponse(tocData, source: source, detailURL: tocURL)
        let expectedTOC = loadExpectedTOC(for: "case_001")

        XCTAssertEqual(tocResult.count, expectedTOC.count, "TOC result count mismatch")
        for (index, item) in tocResult.enumerated() {
            XCTAssertEqual(item.chapterTitle, expectedTOC[index]["chapterTitle"], "ChapterTitle mismatch at index \(index)")
            XCTAssertEqual(item.chapterURL, expectedTOC[index]["chapterURL"], "ChapterURL mismatch at index \(index)")
            XCTAssertEqual(item.chapterIndex, index, "ChapterIndex mismatch at index \(index)")
        }
        print("✓ TOC passed")
        print("  - Found \(tocResult.count) chapters")
        print("  - First chapter: \(tocResult.first?.chapterTitle ?? "N/A") at \(tocResult.first?.chapterURL ?? "N/A")")

        // Step 4: Content - using TOC result's first chapter URL
        print("Step 4: Content (using TOC result's first chapter URL)")
        let contentData = loadFixture(for: "case_001", named: "content")
        let firstChapterURL = tocResult.first?.chapterURL ?? ""
        let contentResult = try engine.parseContentResponse(contentData, source: source, chapterURL: firstChapterURL)
        let expectedContent = loadExpectedContent(for: "case_001")

        XCTAssertEqual(contentResult.title, expectedContent["title"], "Title mismatch")
        XCTAssertEqual(contentResult.content, expectedContent["content"], "Content mismatch")
        XCTAssertEqual(contentResult.chapterURL, expectedContent["chapterURL"], "ChapterURL mismatch")
        print("✓ Content passed")
        print("  - Chapter: \(contentResult.title)")
        print("  - Content length: \(contentResult.content.count) characters")

        print("\n=== FULL PIPELINE PASSED ===")
        print("  Search → Detail → TOC → Content")
        print("  1 book found: '\(bookInfo.bookName)' by \(bookInfo.author)")
        print("  1 chapter read: '\(tocResult.first?.chapterTitle ?? "N/A")'")
    }

    func testCase002() throws {
        try runTestCase(caseId: "case_002", sourceName: "Sample-002-Fixture")
    }

    func testCase003() throws {
        try runTestCase(caseId: "case_003", sourceName: "Sample-003-Fixture")
    }

    func testCase004() throws {
        try runTestCase(caseId: "case_004", sourceName: "Sample-004-Fixture")
    }

    func testCase005() throws {
        try runTestCase(caseId: "case_005", sourceName: "Sample-005-Fixture")
    }

    func testCase006() throws {
        try runTestCase(caseId: "case_006", sourceName: "Sample-006-Fixture")
    }

    func testCase007() throws {
        try runTestCase(caseId: "case_007", sourceName: "Sample-007-Fixture")
    }

    func testCase008() throws {
        try runTestCase(caseId: "case_008", sourceName: "Sample-008-Fixture")
    }

    func testCase009() throws {
        try runTestCase(caseId: "case_009", sourceName: "Sample-009-Fixture")
    }

    func testCase010() throws {
        try runTestCase(caseId: "case_010", sourceName: "Sample-010-Fixture")
    }

    func testCase022() throws {
        try runTestCase(caseId: "case_022", sourceName: "sudugu.org")
    }

    private func runTestCase(caseId: String, sourceName: String) throws {
        print("\n=== Testing Case: \(caseId) - \(sourceName) ===")

        let source = loadBookSource(for: caseId)

        // Step 1: Search
        print("Step 1: Search")
        let searchData = loadFixture(for: caseId, named: "search")
        let searchResult = try engine.parseSearchResponse(searchData, source: source, query: SearchQuery(keyword: "test"))
        let expectedSearch = loadExpectedSearch(for: caseId)

        XCTAssertEqual(searchResult.count, expectedSearch.count, "Search result count mismatch for \(caseId)")
        for (index, item) in searchResult.enumerated() {
            XCTAssertEqual(item.title, expectedSearch[index]["title"], "Title mismatch at index \(index) for \(caseId)")
            XCTAssertEqual(item.detailURL, expectedSearch[index]["detailURL"], "DetailURL mismatch at index \(index) for \(caseId)")
            XCTAssertEqual(item.author, expectedSearch[index]["author"], "Author mismatch at index \(index) for \(caseId)")
        }
        print("✓ Search passed")

        // Step 2: Detail (blocked)
        print("Step 2: Detail (blocked - using search URL)")
        let detailData = loadFixture(for: caseId, named: "detail")
        let firstBookURL = searchResult.first?.detailURL ?? ""
        let bookInfo = try engine.parseBookInfoResponse(detailData, source: source, detailURL: firstBookURL)
        print("  - Book name: \(bookInfo.bookName)")
        print("  - TOC URL: \(bookInfo.tocURL)")

        // Step 3: TOC
        print("Step 3: TOC")
        let tocData = loadFixture(for: caseId, named: "toc")
        let tocResult = try engine.parseTOCResponse(tocData, source: source, detailURL: bookInfo.tocURL)
        let expectedTOC = loadExpectedTOC(for: caseId)

        XCTAssertEqual(tocResult.count, expectedTOC.count, "TOC result count mismatch for \(caseId)")
        for (index, item) in tocResult.enumerated() {
            XCTAssertEqual(item.chapterTitle, expectedTOC[index]["chapterTitle"], "ChapterTitle mismatch at index \(index) for \(caseId)")
            XCTAssertEqual(item.chapterURL, expectedTOC[index]["chapterURL"], "ChapterURL mismatch at index \(index) for \(caseId)")
            XCTAssertEqual(item.chapterIndex, index, "ChapterIndex mismatch at index \(index) for \(caseId)")
        }
        print("✓ TOC passed")

        // Step 4: Content
        print("Step 4: Content")
        let contentData = loadFixture(for: caseId, named: "content")
        let contentResult = try engine.parseContentResponse(contentData, source: source, chapterURL: tocResult.first?.chapterURL ?? "")
        let expectedContent = loadExpectedContent(for: caseId)

        XCTAssertEqual(contentResult.title, expectedContent["title"], "Title mismatch for \(caseId)")
        XCTAssertEqual(contentResult.content, expectedContent["content"], "Content mismatch for \(caseId)")
        XCTAssertEqual(contentResult.chapterURL, expectedContent["chapterURL"], "ChapterURL mismatch for \(caseId)")
        print("✓ Content passed")

        print("=== Test Case \(caseId) PASSED ===\n")
    }
}