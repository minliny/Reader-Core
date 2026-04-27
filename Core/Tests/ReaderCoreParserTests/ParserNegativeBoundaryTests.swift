import XCTest
import ReaderCoreParser
import ReaderCoreModels

/// Negative boundary tests for V2 parser unsupported selector forms.
///
/// Each test proves that a specific unsupported selector form returns 0 matches —
/// i.e., the parser does NOT silently misfire on unsupported syntax.
///
/// Cases mirror samples/real_world/parser_negative_cases/negative_case_001 – 006.
/// No @testable — public API only, matching iOS consumer call style.
final class ParserNegativeBoundaryTests: XCTestCase {

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
            bookSourceName: "negative-boundary-fixture",
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
            .appendingPathComponent("samples/real_world/parser_negative_cases")
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
        let result = matches(selector: sample.selector, html: sample.html)
        XCTAssertEqual(result.count, sample.expected.matchCount, "\(id): expected match count", file: file, line: line)
        XCTAssertEqual(result, sample.expected.expectedMatches, "\(id): expected matches", file: file, line: line)
    }

    /// Unsupported selectors may surface as an empty result or an empty-result parsing error.
    /// Both preserve the V2 contract: no accidental broader match.
    private func matches(selector: String, html: String) -> [String] {
        let result = try? NonJSParserEngine().parseSearchResponse(
            Data(html.utf8),
            source: source(css: selector),
            query: SearchQuery(keyword: "test")
        )
        return result?.map(\.title) ?? []
    }

    // MARK: - negative_case_001: tag#id

    /// `div#main` is rejected by the V2 strict simple-selector grammar.
    /// Proves: tag#id is NOT accidentally treated as tag+id compound.
    func testNegative001_tagHashId_returnsZeroMatches() throws {
        try assertCase("negative_case_001")
    }

    // MARK: - negative_case_002: descendant selector

    /// `div .title` is rejected by the V2 strict simple-selector grammar.
    /// Proves: descendant syntax is NOT accidentally partially resolved.
    func testNegative002_descendantSelector_returnsZeroMatches() throws {
        try assertCase("negative_case_002")
    }

    // MARK: - negative_case_003: direct child selector

    /// `div > span` is rejected by the V2 strict simple-selector grammar.
    func testNegative003_directChildSelector_returnsZeroMatches() throws {
        try assertCase("negative_case_003")
    }

    // MARK: - negative_case_004: attribute selector

    /// `a[href]` is rejected by the V2 strict simple-selector grammar.
    /// Proves: attribute selectors are NOT accidentally treated as bare tag names.
    func testNegative004_attributeSelector_returnsZeroMatches() throws {
        try assertCase("negative_case_004")
    }

    // MARK: - negative_case_005: multiple selector group

    /// `div, span` is rejected by the V2 strict simple-selector grammar.
    /// Proves: comma is NOT interpreted as a selector group separator.
    func testNegative005_multipleSelectorGroup_returnsZeroMatches() throws {
        try assertCase("negative_case_005")
    }

    // MARK: - negative_case_006: pseudo-class

    /// `li:first-child` is rejected by the V2 strict simple-selector grammar.
    /// Proves: pseudo-classes are NOT accidentally resolved by position logic.
    func testNegative006_pseudoClass_returnsZeroMatches() throws {
        try assertCase("negative_case_006")
    }
}
