import XCTest
@testable import ReaderCoreParser
import ReaderCoreModels

/// Validates the CSS selector engine against 5 real-world sample cases
/// stored in `samples/real_world/parser_cases/`.
///
/// Each test corresponds to one case directory (case_001 … case_005).
/// Each test reads `input.html`, `selector.txt`, and `expected.json` from
/// the sample directory to keep the sample -> expected -> test closure intact.
/// Tests drive `NonJSParserEngine` via `parseSearchResponse`, the same
/// public entry point used in production.
final class RealWorldParserCasesTests: XCTestCase {

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
            bookSourceName: "rw-cases-fixture",
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

    private func matches(selector: String, html: String) throws -> [String] {
        let result = try NonJSParserEngine().parseSearchResponse(
            Data(html.utf8),
            source: source(css: selector),
            query: SearchQuery(keyword: "test")
        )
        return result.map(\.title)
    }

    // MARK: - case_001: .class — multiple hits

    func testCase001_dotClass_multipleHits() throws {
        let sample = try loadCase("case_001")
        let result = try matches(selector: sample.selector, html: sample.html)
        XCTAssertEqual(result.count, sample.expected.matchCount, "case_001: expected match count")
        XCTAssertEqual(result, sample.expected.expectedMatches, "case_001: expected matches")
    }

    // MARK: - case_002: #id — single hit

    func testCase002_hashId_singleHit() throws {
        let sample = try loadCase("case_002")
        let result = try matches(selector: sample.selector, html: sample.html)
        XCTAssertEqual(result.count, sample.expected.matchCount, "case_002: expected match count")
        XCTAssertEqual(result, sample.expected.expectedMatches, "case_002: expected matches")
    }

    // MARK: - case_003: tag — three hits

    func testCase003_tag_threeHits() throws {
        let sample = try loadCase("case_003")
        let result = try matches(selector: sample.selector, html: sample.html)
        XCTAssertEqual(result.count, sample.expected.matchCount, "case_003: expected match count")
        XCTAssertEqual(result, sample.expected.expectedMatches, "case_003: expected matches")
    }

    // MARK: - case_004: tag.class — filters by both tag and class

    func testCase004_tagDotClass_filtersNonMatchingTag() throws {
        let sample = try loadCase("case_004")
        let result = try matches(selector: sample.selector, html: sample.html)
        XCTAssertEqual(result.count, sample.expected.matchCount, "case_004: expected match count")
        XCTAssertEqual(result, sample.expected.expectedMatches, "case_004: expected matches")
    }

    // MARK: - case_005: boundary — multi-class element, partial class match

    func testCase005_boundary_multiClassElement_matchesWhenTargetClassPresent() throws {
        let sample = try loadCase("case_005")
        let result = try matches(selector: sample.selector, html: sample.html)
        XCTAssertEqual(result.count, sample.expected.matchCount, "case_005: expected match count")
        XCTAssertEqual(result, sample.expected.expectedMatches, "case_005: expected matches")
    }
}
