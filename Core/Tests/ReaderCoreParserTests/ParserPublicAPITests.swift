// Simulates how an iOS app consumer would call the Parser public API.
// Intentionally does NOT use @testable — only public symbols are accessed,
// exactly as an external Swift Package consumer on iOS would call them.
import XCTest
import ReaderCoreParser
import ReaderCoreModels

final class ParserPublicAPITests: XCTestCase {

    // MARK: - Minimal integration: li.searchresult

    func testPublicAPI_tagDotClass_returnsExpectedMatch() throws {
        let html = #"<li class="searchresult">A</li>"#

        let source = BookSource(
            bookSourceName: "ios-integration-check",
            bookSourceUrl: "http://fixture.local",
            searchUrl: "http://fixture.local/s/{{key}}",
            ruleSearch: "css:li.searchresult",
            ruleToc: "css:a",
            ruleContent: "css:div"
        )

        let engine = NonJSParserEngine()
        let results = try engine.parseSearchResponse(
            Data(html.utf8),
            source: source,
            query: SearchQuery(keyword: "test")
        )

        XCTAssertEqual(results.count, 1,
            "iOS integration: expected exactly 1 result for li.searchresult")
        XCTAssertEqual(results[0].title, "A",
            "iOS integration: result title must equal 'A'")
    }
}
