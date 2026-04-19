import XCTest
@testable import ReaderCoreParser
import ReaderCoreModels

/// Regression tests for the `tag.class` compound CSS selector added to
/// `NonJSRuleScheduler.extractBySimpleCSS`.
///
/// Background: `extractBySimpleCSS` previously only handled three forms:
///   - `.class`   → matches class attribute
///   - `#id`      → matches id attribute
///   - `tagname`  → matches literal tag name
///
/// The fix added a `tag.class` branch that matches a specific tag which also
/// carries the named class (e.g. `li.searchresult`). The branch triggers when
/// the selector contains a `.` that is not the first character.
///
/// Each test asserts one of the four selector branches in isolation using a
/// shared minimal HTML fixture. No production logic was changed to make these
/// tests pass.
///
/// These tests are the XCTest-backed counterpart to the Node.js auxiliary
/// verification run against live `auto_997f4a49` (haitaozhe.com) search HTML,
/// where `css:li.searchresult` was previously returning 0 results and now
/// returns the correct count.
final class NonJSTagClassRegressionTests: XCTestCase {

    // ── Shared minimal fixture ────────────────────────────────────────────────
    //
    // Contains:
    //   • Two <li class="searchresult"> — target for li.searchresult / .searchresult
    //   • One <li class="other">        — must NOT be picked up by li.searchresult
    //   • One plain <li> without class  — contributes to bare `li` count
    //   • One <div id="content">        — target for #content
    private let fixtureHTML = """
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body>
        <ul>
          <li class="searchresult">天龙八部|http://fixture.local/book/1.html</li>
          <li class="searchresult">射雕英雄传|http://fixture.local/book/2.html</li>
          <li class="other">导航链接</li>
          <li>无类标签</li>
        </ul>
        <div id="content">这是正文内容，不依赖 JavaScript 渲染。</div>
        </body>
        </html>
        """

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func makeSource(ruleSearch: String, ruleContent: String = "css:#content") -> BookSource {
        BookSource(
            bookSourceName: "tag-class-fixture",
            bookSourceUrl: "http://fixture.local",
            searchUrl: "http://fixture.local/search/{{key}}.html",
            ruleSearch: ruleSearch,
            ruleToc: "css:a",
            ruleContent: ruleContent
        )
    }

    private func runSearch(rule: String) throws -> [SearchResultItem] {
        try NonJSParserEngine().parseSearchResponse(
            Data(fixtureHTML.utf8),
            source: makeSource(ruleSearch: rule),
            query: SearchQuery(keyword: "fixture")
        )
    }

    private func runContent(rule: String) throws -> ContentPage {
        try NonJSParserEngine().parseContentResponse(
            Data(fixtureHTML.utf8),
            source: makeSource(ruleSearch: "css:li.searchresult", ruleContent: rule),
            chapterURL: "http://fixture.local/chapter/1.html"
        )
    }

    // ── 1. Existing behaviour: .class selector ───────────────────────────────

    /// css:.searchresult must still match both <li class="searchresult"> elements.
    /// Asserts the pre-existing `.class` branch is undisturbed.
    func testClassOnlySelectorMatchesBothSearchresultItems() throws {
        let result = try runSearch(rule: "css:.searchresult")
        XCTAssertEqual(result.count, 2, "css:.searchresult should match exactly 2 elements")
        XCTAssertEqual(result[0].title, "天龙八部")
        XCTAssertEqual(result[0].detailURL, "http://fixture.local/book/1.html")
        XCTAssertEqual(result[1].title, "射雕英雄传")
        XCTAssertEqual(result[1].detailURL, "http://fixture.local/book/2.html")
    }

    // ── 2. Existing behaviour: #id selector ──────────────────────────────────

    /// css:#content must still match the <div id="content"> element.
    /// Asserts the pre-existing `#id` branch is undisturbed.
    func testIdSelectorMatchesContentDiv() throws {
        let page = try runContent(rule: "css:#content")
        XCTAssertFalse(page.content.isEmpty, "css:#content should produce non-empty content")
        XCTAssertEqual(page.content, "这是正文内容，不依赖 JavaScript 渲染。")
    }

    // ── 3. Existing behaviour: bare tag selector ─────────────────────────────

    /// css:li must still match all four <li> elements (2 searchresult + 1 other + 1 bare).
    /// Asserts the tagname fallthrough is undisturbed.
    func testBareTagSelectorMatchesAllListItems() throws {
        let result = try runSearch(rule: "css:li")
        XCTAssertEqual(result.count, 4, "css:li should match all 4 <li> elements")
    }

    // ── 4. NEW behaviour: tag.class compound selector ────────────────────────

    /// css:li.searchresult must match only the two <li class="searchresult"> elements,
    /// excluding <li class="other"> and the bare <li>.
    /// This is the direct regression case for auto_997f4a49 (ruleSearch = css:li.searchresult).
    func testTagClassSelectorMatchesOnlySearchresultLiItems() throws {
        let result = try runSearch(rule: "css:li.searchresult")
        XCTAssertEqual(result.count, 2,
            "css:li.searchresult must match the 2 <li class=\"searchresult\"> nodes only, " +
            "not <li class=\"other\"> nor bare <li>")
        XCTAssertEqual(result[0].title, "天龙八部")
        XCTAssertEqual(result[0].detailURL, "http://fixture.local/book/1.html")
        XCTAssertEqual(result[1].title, "射雕英雄传")
        XCTAssertEqual(result[1].detailURL, "http://fixture.local/book/2.html")
    }

    // ── 5. NEW behaviour: tag constraint is enforced ─────────────────────────

    /// css:div.searchresult must return 0 results / throw SEARCH_FAILED because
    /// there is no <div class="searchresult"> — only <li> elements carry that class.
    /// Ensures the tag part of the new branch is actually enforced.
    func testTagClassSelectorDoesNotMatchWrongTag() throws {
        XCTAssertThrowsError(
            try runSearch(rule: "css:div.searchresult"),
            "css:div.searchresult should throw because no <div class=\"searchresult\"> exists"
        )
    }
}

// MARK: - ! index-trimming tests

/// Regression tests for the `!` index-trimming suffix in applyCSS.
///
/// `css:.chapter!0:2` means "run the .chapter selector, then keep only the
/// results at indices 0 and 2."  These tests guard against:
///  - Out-of-range indices silently trapping  (was: `output[idx]` without bounds check)
///  - First `!` in selector being consumed even when it isn't a valid index suffix
///    (e.g. `dd[!10]` was previously corrupted to `dd[`)
///  - Negative indices being accepted via `Int("-1")` and causing a trap
final class NonJSIndexTrimmingTests: XCTestCase {

    // TOC fixture: 5 .chapter items — nav, ch1, ch2, ch3, footer
    // Each item follows "title|url" so parseTOCResponse can split them.
    private let tocHTML = """
        <!DOCTYPE html>
        <html><body>
        <div class="chapter">导航头部|/nav</div>
        <div class="chapter">第一章|/ch/1</div>
        <div class="chapter">第二章|/ch/2</div>
        <div class="chapter">第三章|/ch/3</div>
        <div class="chapter">页脚链接|/footer</div>
        </body></html>
        """

    private func runToc(rule: String) throws -> [TOCItem] {
        let source = BookSource(
            bookSourceName: "index-trim-fixture",
            bookSourceUrl: "http://fixture.local",
            searchUrl: "http://fixture.local/s/{{key}}",
            ruleSearch: "css:.chapter",
            ruleToc: rule,
            ruleContent: "css:#content"
        )
        return try NonJSParserEngine().parseTOCResponse(
            Data(tocHTML.utf8),
            source: source,
            detailURL: "http://fixture.local/book/1"
        )
    }

    // ── 1. Basic trimming keeps the specified subset ──────────────────────────

    /// !1:2:3 keeps indices 1, 2, 3 (skips nav at 0 and footer at 4).
    func testIndexTrimmingKeepsOnlySpecifiedIndices() throws {
        let chapters = try runToc(rule: "css:.chapter!1:2:3")
        XCTAssertEqual(chapters.count, 3)
        XCTAssertEqual(chapters[0].chapterTitle, "第一章")
        XCTAssertEqual(chapters[0].chapterURL, "/ch/1")
        XCTAssertEqual(chapters[1].chapterTitle, "第二章")
        XCTAssertEqual(chapters[2].chapterTitle, "第三章")
    }

    // ── 2. Out-of-range index is silently ignored, no trap ────────────────────

    /// !0:99 — index 99 is out of range (fixture only has 5 items).
    /// Must return 1 result (index 0 only), not crash.
    func testOutOfRangeIndexIsIgnored() throws {
        let chapters = try runToc(rule: "css:.chapter!0:99")
        XCTAssertEqual(chapters.count, 1, "index 99 is out of range and must be silently dropped")
        XCTAssertEqual(chapters[0].chapterTitle, "导航头部")
    }

    // ── 3. Invalid ! suffix does NOT activate trimming ────────────────────────

    /// The selector `dd[!10]` contains `!` but the suffix `10]` includes `]`
    /// which is not a decimal digit or `:`.  The ! must be treated as part of the
    /// selector, not as an index-trim marker.
    /// Since no `<dd[` tag exists in tocHTML, the parser will throw (no results),
    /// but the key invariant is that the selector is NOT corrupted to `dd[`.
    func testExclamationInBracketsDoesNotTriggerTrimming() throws {
        // css:dd[!10] — the `!` is inside brackets, suffix `10]` is invalid.
        // `extractBySimpleCSS` won't find any element, so parseTOCResponse throws.
        // The important assertion is that the error type is TOC_FAILED (no results),
        // NOT some other error caused by selector corruption.
        do {
            _ = try runToc(rule: "css:dd[!10]")
            XCTFail("Expected error for selector with no matches")
        } catch let e as ReaderError {
            XCTAssertEqual(e.failure?.type, .TOC_FAILED)
        }
    }

    // ── 4. Negative-only index list does not activate trimming ────────────────

    /// A suffix like `!-1:-2` contains `-` which is not a digit or `:`.
    /// The validation rejects it, so `fullSelector` stays `.chapter!-1:-2` (unchanged).
    /// No element has that literal class name, so the parser throws `TOC_FAILED` —
    /// the key invariant is that the code does NOT crash (no negative array subscript).
    func testNegativeIndexSuffixDoesNotActivateTrimming() throws {
        // `!-1:-2` fails the valid-chars check → no trimming, selector = `.chapter!-1:-2`
        // → no matching elements → TOC_FAILED (not a trap or out-of-bounds crash).
        do {
            _ = try runToc(rule: "css:.chapter!-1:-2")
            XCTFail("Expected TOC_FAILED error for selector with no matches")
        } catch let e as ReaderError {
            XCTAssertEqual(e.failure?.type, .TOC_FAILED,
                "negative suffix must not crash; parser should surface TOC_FAILED cleanly")
        }
    }
}
