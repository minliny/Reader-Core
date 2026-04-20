import XCTest
@testable import ReaderCoreParser
import ReaderCoreModels

final class SimpleSelectorContractTests: XCTestCase {

    private let fixtureHTML = """
        <div class="item">Item 1</div>
        <div id="main">Main</div>
        <li class="searchresult">Book Title</li>
        <span class="a b">Span AB</span>
        <div class="chapter">导航|/nav</div>
        <div class="chapter">第一章|/ch/1</div>
        """

    private func runSearch(_ selector: String) -> [SearchResultItem] {
        let source = BookSource(
            bookSourceName: "contract-fixture",
            bookSourceUrl: "http://fixture.local",
            searchUrl: "http://fixture.local/s/{{key}}",
            ruleSearch: "css:\(selector)",
            ruleToc: "css:a",
            ruleContent: "css:div"
        )
        return (try? NonJSParserEngine().parseSearchResponse(
            Data(fixtureHTML.utf8),
            source: source,
            query: SearchQuery(keyword: "contract")
        )) ?? []
    }

    private func runToc(_ rule: String) -> [TOCItem] {
        let source = BookSource(
            bookSourceName: "contract-fixture",
            bookSourceUrl: "http://fixture.local",
            searchUrl: "http://fixture.local/s/{{key}}",
            ruleSearch: "css:div",
            ruleToc: rule,
            ruleContent: "css:div"
        )
        return (try? NonJSParserEngine().parseTOCResponse(
            Data(fixtureHTML.utf8),
            source: source,
            detailURL: "http://fixture.local/book/1"
        )) ?? []
    }

    // MARK: - Contract 1: Unsupported selectors MUST NOT fallback to tag literal

    func testTagHashSelectorMustNotFallback() {
        let results = runSearch("div#main")
        XCTAssertTrue(results.isEmpty,
            "Contract: tag#id is unsupported. Parser must NOT fallback to 'div' tag literal.")
    }

    func testMultiClassSelectorMustNotFallback() {
        let results = runSearch(".a.b")
        XCTAssertTrue(results.isEmpty,
            "Contract: multi-class .a.b is unsupported. Parser must NOT match .a then fallback.")
    }

    func testDescendantSelectorMustNotFallback() {
        let results = runSearch("div .item")
        XCTAssertTrue(results.isEmpty,
            "Contract: descendant selector (space) is unsupported. Parser must NOT match 'div' then fallback.")
    }

    // MARK: - Contract 2: tag.class must strictly match tag AND class

    func testTagClassMatchesOnlyExactTag() {
        let results = runSearch("li.searchresult")
        XCTAssertEqual(results.count, 1,
            "Contract: li.searchresult must match only <li class='searchresult'>, not <div class='searchresult'>")
        if let first = results.first {
            XCTAssertEqual(first.title, "Book Title")
        }
    }

    func testTagClassDoesNotMatchOtherTag() {
        let results = runSearch("div.searchresult")
        XCTAssertEqual(results.count, 0,
            "Contract: div.searchresult must NOT match <li class='searchresult'>. Tag constraint is enforced.")
    }

    // MARK: - Contract 3: Trimming suffix is independent from selector parsing

    func testNegativeIndexDoesNotActivateTrimming() {
        let chapters = runToc("css:.chapter!-1")
        XCTAssertTrue(chapters.isEmpty,
            "Contract: !-1 is invalid trimming suffix. Selector should be treated as literal '.chapter!-1' with 0 matches, not crash.")
    }

    func testExclamationInAttributeDoesNotTriggerTrimming() {
        let chapters = runToc("css:dd[!10]")
        XCTAssertTrue(chapters.isEmpty,
            "Contract: dd[!10] has ! inside brackets. ! must NOT be treated as trimming suffix.")
    }

    func testValidTrimmingStillWorks() {
        let chapters = runToc("css:.chapter!0")
        XCTAssertEqual(chapters.count, 1,
            "Contract: !0 is valid trimming suffix. Should keep only index 0.")
        if let first = chapters.first {
            XCTAssertEqual(first.chapterTitle, "导航")
        }
    }
}
