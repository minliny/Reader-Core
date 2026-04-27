import XCTest
import ReaderCoreParser
import ReaderCoreModels

/// Extended real-world parser cases (case_006 – case_020).
/// Covers V2 stable selector subset only: .class / #id / tag / tag.class.
/// No @testable — simulates external consumer call style.
final class RealWorldParserCasesExtendedTests: XCTestCase {

    private struct Expected: Decodable {
        let expectedMatches: [String]
        let matchCount: Int

        enum CodingKeys: String, CodingKey {
            case expectedMatches = "expected_matches"
            case matchCount = "match_count"
        }
    }

    private func source(css selector: String) -> BookSource {
        BookSource(
            bookSourceName: "rw-extended-fixture",
            bookSourceUrl: "http://fixture.local",
            searchUrl: "http://fixture.local/s/{{key}}",
            ruleSearch: "css:\(selector)",
            ruleToc: "css:a",
            ruleContent: "css:div"
        )
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func loadCase(_ id: String) throws -> (selector: String, html: String, expected: Expected) {
        let caseRoot = repoRoot()
            .appendingPathComponent("samples/real_world/parser_cases")
            .appendingPathComponent(id)

        let selector = try String(contentsOf: caseRoot.appendingPathComponent("selector.txt"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let html = try String(contentsOf: caseRoot.appendingPathComponent("input.html"), encoding: .utf8)
        let expected = try JSONDecoder().decode(
            Expected.self,
            from: Data(contentsOf: caseRoot.appendingPathComponent("expected.json"))
        )
        return (selector, html, expected)
    }

    private func assertCase(_ id: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let sample = try loadCase(id)
        let result = try matches(selector: sample.selector, html: sample.html)
        XCTAssertEqual(result.count, sample.expected.matchCount, "\(id): expected match count", file: file, line: line)
        XCTAssertEqual(result, sample.expected.expectedMatches, "\(id): expected matches", file: file, line: line)
    }

    private func matches(selector: String, html: String) throws -> [String] {
        let result = try NonJSParserEngine().parseSearchResponse(
            Data(html.utf8),
            source: source(css: selector),
            query: SearchQuery(keyword: "test")
        )
        return result.map(\.title)
    }

    // MARK: - case_006: tag.class — div.chapter

    func testCase006_tagDotClass_divChapter() throws {
        try assertCase("case_006")
    }

    // MARK: - case_007: .class — .result-title (4 hits)

    func testCase007_dotClass_resultTitle_fourHits() throws {
        try assertCase("case_007")
    }

    // MARK: - case_008: #id — #book-detail

    func testCase008_hashId_bookDetail() throws {
        try assertCase("case_008")
    }

    // MARK: - case_009: tag — h3

    func testCase009_tag_h3_excludesH4() throws {
        try assertCase("case_009")
    }

    // MARK: - case_010: tag.class — span.author excludes div.author

    func testCase010_tagDotClass_spanAuthor_excludesDivAuthor() throws {
        try assertCase("case_010")
    }

    // MARK: - case_011: .class — .catalog-item (5 hits)

    func testCase011_dotClass_catalogItem_fiveHits() throws {
        try assertCase("case_011")
    }

    // MARK: - case_012: #id — #content-area

    func testCase012_hashId_contentArea() throws {
        try assertCase("case_012")
    }

    // MARK: - case_013: tag — td (6 cells across two rows)

    func testCase013_tag_td_sixCells() throws {
        try assertCase("case_013")
    }

    // MARK: - case_014: tag.class — p.desc excludes p.note

    func testCase014_tagDotClass_pDesc_excludesPNote() throws {
        try assertCase("case_014")
    }

    // MARK: - case_015: boundary — class name with hyphen (.search-result)

    func testCase015_boundary_classNameWithHyphen() throws {
        try assertCase("case_015")
    }

    // MARK: - case_016: tag.class — tr.item excludes tr.header-row

    func testCase016_tagDotClass_trItem() throws {
        try assertCase("case_016")
    }

    // MARK: - case_017: boundary — id with hyphen (#main-content)

    func testCase017_boundary_idWithHyphen() throws {
        try assertCase("case_017")
    }

    // MARK: - case_018: tag — h1 (single, h2 excluded)

    func testCase018_tag_h1_singleHit() throws {
        try assertCase("case_018")
    }

    // MARK: - case_019: tag.class — a.chapter-link excludes a.nav-link

    func testCase019_tagDotClass_aChapterLink() throws {
        try assertCase("case_019")
    }

    // MARK: - case_020: boundary — single-item result set (.book-entry)

    func testCase020_boundary_singleItemResultSet() throws {
        try assertCase("case_020")
    }
}
