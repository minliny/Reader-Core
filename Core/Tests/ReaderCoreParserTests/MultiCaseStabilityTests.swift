import XCTest
import ReaderCoreParser
import ReaderCoreModels

final class MultiCaseStabilityTests: XCTestCase {
    private let repoRoot = "/Users/minliny/Documents/Reader-Core"

    func testCase022AndCase023RemainStableInSingleParserRun() throws {
        let engine = NonJSParserEngine()

        let case022 = try evaluateCase022(using: engine)
        let case023 = try evaluateCase023(using: engine)

        XCTAssertTrue(case022.detailPass, "case_022 detail must remain PASS")
        XCTAssertTrue(case022.tocPass, "case_022 toc must remain PASS")
        XCTAssertTrue(case022.contentPass, "case_022 content must remain PASS")
        XCTAssertEqual(case022.chapterCount, 659)
        XCTAssertEqual(case022.contentLength, 3465)

        XCTAssertTrue(case023.detailPass, "case_023 detail must remain PASS")
        XCTAssertTrue(case023.tocPass, "case_023 toc must remain PASS")
        XCTAssertTrue(case023.contentPass, "case_023 content must remain PASS")
        XCTAssertEqual(case023.chapterCount, 165)
        XCTAssertEqual(case023.contentLength, 722016)
    }

    func testStatusMarkersRemainNonBaseline() {
        let report = read("samples/real_world/non_js/regression_report.md")
        let case022Metadata = read("samples/real_world/non_js/case_022/metadata.yml")
        let case023Metadata = read("samples/real_world/non_js/case_023/metadata.yml")

        assertContains(case022Metadata, "FIRST_REAL_PASS_CASE_ESTABLISHED", in: "case_022/metadata.yml")
        assertContains(case023Metadata, "SECOND_REAL_PASS_CASE_ESTABLISHED", in: "case_023/metadata.yml")
        assertContains(report, "FIRST_REAL_PASS_CASE_ESTABLISHED", in: "regression_report.md")
        assertContains(report, "SECOND_REAL_PASS_CASE_ESTABLISHED", in: "regression_report.md")
        assertContains(report, "NOT baseline ready", in: "regression_report.md")
        assertNotContains(report, "BASELINE_READY", in: "regression_report.md")
    }

    func testCasesUseIndependentFixturesAndRules() throws {
        let case022Root = caseRoot("case_022")
        let case023Root = caseRoot("case_023")

        XCTAssertNotEqual(case022Root.path, case023Root.path)
        for name in ["detail", "toc", "content"] {
            let case022Fixture = fixtureURL(caseID: "case_022", name: name)
            let case023Fixture = fixtureURL(caseID: "case_023", name: name)

            XCTAssertNotEqual(case022Fixture.path, case023Fixture.path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: case022Fixture.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: case023Fixture.path))
        }

        let case022Source = try loadSource(caseID: "case_022")
        let case023Source = try loadSource(caseID: "case_023")

        XCTAssertNotEqual(case022Source.bookSourceUrl, case023Source.bookSourceUrl)
        XCTAssertNotEqual(case022Source.ruleToc, case023Source.ruleToc)
        XCTAssertNotEqual(case022Source.ruleContent, case023Source.ruleContent)

        XCTAssertEqual(case022Source.ruleBookInfo, "css:h1")
        XCTAssertEqual(case023Source.ruleBookInfo, "css:h1")
        XCTAssertEqual(case022Source.ruleToc, "css:#list a@href")
        XCTAssertEqual(case023Source.ruleToc, "css:a@href")
        XCTAssertEqual(case022Source.ruleContent, "css:.con")
        XCTAssertEqual(case023Source.ruleContent, "css:body")
    }

    func testNoCrossCaseFallback() throws {
        let engine = NonJSParserEngine()
        let case022Source = try loadSource(caseID: "case_022")
        let case023Source = try loadSource(caseID: "case_023")

        let case023RuleOnCase022Content = try engine.parseContentResponse(
            loadFixture(caseID: "case_022", name: "content"),
            source: case023Source,
            chapterURL: "https://www.sudugu.org/51/3612068.html"
        )
        XCTAssertNotEqual(
            case023RuleOnCase022Content.content.count,
            722016,
            "case_023 ruleContent must not fallback to the canonical case_023 content when run against case_022 fixtures"
        )

        XCTAssertThrowsError(
            try engine.parseContentResponse(
                loadFixture(caseID: "case_023", name: "content"),
                source: case022Source,
                chapterURL: "https://www.gutenberg.org/files/1342/1342-h/1342-h.htm"
            ),
            "case_022 ruleContent must not fallback into case_023 fixtures"
        )
    }

    private struct CaseResult {
        let detailPass: Bool
        let tocPass: Bool
        let contentPass: Bool
        let chapterCount: Int
        let contentLength: Int
    }

    private func evaluateCase022(using engine: NonJSParserEngine) throws -> CaseResult {
        let source = try loadSource(caseID: "case_022")
        let detailURL = "https://www.sudugu.org/51/"
        let contentURL = "https://www.sudugu.org/51/3612068.html"

        let info = try engine.parseBookInfoResponse(
            loadFixture(caseID: "case_022", name: "detail"),
            source: source,
            detailURL: detailURL
        )
        let toc = try engine.parseTOCResponse(
            loadFixture(caseID: "case_022", name: "toc"),
            source: source,
            detailURL: info.tocURL
        )
        let content = try engine.parseContentResponse(
            loadFixture(caseID: "case_022", name: "content"),
            source: source,
            chapterURL: contentURL
        )

        return CaseResult(
            detailPass: !info.tocURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            tocPass: !toc.isEmpty,
            contentPass: content.content.count > 100,
            chapterCount: toc.count,
            contentLength: content.content.count
        )
    }

    private func evaluateCase023(using engine: NonJSParserEngine) throws -> CaseResult {
        let source = try loadSource(caseID: "case_023")
        let detailURL = "https://www.gutenberg.org/files/1342/1342-h/1342-h.htm"

        let info = try engine.parseBookInfoResponse(
            loadFixture(caseID: "case_023", name: "detail"),
            source: source,
            detailURL: detailURL
        )
        let toc = try engine.parseTOCResponse(
            loadFixture(caseID: "case_023", name: "toc"),
            source: source,
            detailURL: info.tocURL
        )
        let content = try engine.parseContentResponse(
            loadFixture(caseID: "case_023", name: "content"),
            source: source,
            chapterURL: detailURL
        )

        return CaseResult(
            detailPass: !info.tocURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            tocPass: !toc.isEmpty,
            contentPass: content.content.count > 100,
            chapterCount: toc.count,
            contentLength: content.content.count
        )
    }

    private func loadSource(caseID: String) throws -> BookSource {
        let url = caseRoot(caseID).appendingPathComponent("booksource.json")
        return try JSONDecoder().decode(BookSource.self, from: Data(contentsOf: url))
    }

    private func loadFixture(caseID: String, name: String) throws -> Data {
        try Data(contentsOf: fixtureURL(caseID: caseID, name: name))
    }

    private func fixtureURL(caseID: String, name: String) -> URL {
        caseRoot(caseID)
            .appendingPathComponent("fixtures")
            .appendingPathComponent("\(name).html")
    }

    private func caseRoot(_ caseID: String) -> URL {
        URL(fileURLWithPath: repoRoot)
            .appendingPathComponent("samples/real_world/non_js")
            .appendingPathComponent(caseID)
    }

    private func read(_ relativePath: String, file: StaticString = #file, line: UInt = #line) -> String {
        let url = URL(fileURLWithPath: repoRoot).appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            XCTFail("stability: required file missing or unreadable: \(relativePath)", file: file, line: line)
            return ""
        }
        return text
    }

    private func assertContains(_ text: String, _ needle: String, in label: String,
                                file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(
            text.contains(needle),
            "stability: \(label) is missing required token: \"\(needle)\"",
            file: file,
            line: line
        )
    }

    private func assertNotContains(_ text: String, _ needle: String, in label: String,
                                   file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(
            text.contains(needle),
            "stability: \(label) must NOT contain forbidden token: \"\(needle)\"",
            file: file,
            line: line
        )
    }
}
