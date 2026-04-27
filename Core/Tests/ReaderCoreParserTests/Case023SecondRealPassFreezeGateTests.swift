import XCTest
import ReaderCoreParser
import ReaderCoreModels

final class Case023SecondRealPassCandidateTests: XCTestCase {
    private let caseRoot = "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/case_023"

    func testCase023SecondRealPassCandidate() throws {
        let engine = NonJSParserEngine()
        let source = try loadSource()
        let detailURL = "https://www.gutenberg.org/files/1342/1342-h/1342-h.htm"

        let info = try engine.parseBookInfoResponse(
            loadFixture("detail"),
            source: source,
            detailURL: detailURL
        )
        let toc = try engine.parseTOCResponse(
            loadFixture("toc"),
            source: source,
            detailURL: info.tocURL
        )
        let content = try engine.parseContentResponse(
            loadFixture("content"),
            source: source,
            chapterURL: detailURL
        )

        XCTAssertFalse(info.tocURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertEqual(toc.count, 165)
        XCTAssertEqual(toc.first?.chapterTitle, "#PREFACE")
        XCTAssertEqual(toc.first?.chapterURL, "#PREFACE")
        XCTAssertGreaterThan(content.content.count, 100)
        XCTAssertEqual(content.content.count, 722016)
    }

    private func loadSource() throws -> BookSource {
        let url = URL(fileURLWithPath: "\(caseRoot)/booksource.json")
        return try JSONDecoder().decode(BookSource.self, from: Data(contentsOf: url))
    }

    private func loadFixture(_ name: String) throws -> Data {
        let url = URL(fileURLWithPath: "\(caseRoot)/fixtures/\(name).html")
        return try Data(contentsOf: url)
    }
}

final class Case023SecondRealPassFreezeGateTests: XCTestCase {
    private let repoRoot = "/Users/minliny/Documents/Reader-Core"

    func test_case023_metadata_locked() {
        let metadata = read("samples/real_world/non_js/case_023/metadata.yml")

        assertContains(metadata, "marker: SECOND_REAL_PASS_CASE_ESTABLISHED", in: "case_023/metadata.yml")
        assertContains(metadata, "status: PASS_WITH_LIMITATIONS", in: "case_023/metadata.yml")
        assertContains(metadata, "parser_source_modified: false", in: "case_023/metadata.yml")
    }

    func test_case023_report_locked() {
        let report = read("samples/real_world/non_js/case_023/second_real_pass_report.txt")

        assertContains(report, "SECOND_REAL_PASS_CASE: YES", in: "second_real_pass_report.txt")
        assertContains(report, "status: PASS", in: "second_real_pass_report.txt")
        assertContains(report, "detail:", in: "second_real_pass_report.txt")
        assertContains(report, "toc:", in: "second_real_pass_report.txt")
        assertContains(report, "content:", in: "second_real_pass_report.txt")
        assertContains(report, "chapter_count: 165", in: "second_real_pass_report.txt")
        assertContains(report, "content_length: 722016", in: "second_real_pass_report.txt")
    }

    func test_regression_report_records_second_pass_without_baseline_upgrade() {
        let report = read("samples/real_world/non_js/regression_report.md")

        assertContains(report, "real_valid_pass_cases = 2", in: "regression_report.md")
        assertContains(report, "SECOND_REAL_PASS_CASE_ESTABLISHED", in: "regression_report.md")
        assertContains(report, "case_022 = FIRST_REAL_PASS_CASE", in: "regression_report.md")
        assertContains(report, "case_023 = SECOND_REAL_PASS_CASE", in: "regression_report.md")
        assertContains(report, "NOT baseline ready", in: "regression_report.md")

        assertNotContains(report, "NON_JS_REAL_WORLD_REGRESSION_BASELINE_READY", in: "regression_report.md")
        assertNotContains(report, "BASELINE_READY", in: "regression_report.md")
    }

    func test_known_limitations_are_non_blocking() {
        let metadata = read("samples/real_world/non_js/case_023/metadata.yml")
        let readme = read("samples/real_world/non_js/case_023/README.md")
        let expected = read("samples/real_world/non_js/case_023/expected/toc_result.json")

        assertContains(metadata, "chapterTitle == chapterURL", in: "case_023/metadata.yml")
        assertContains(metadata, "known_issue", in: "case_023/metadata.yml")
        assertContains(readme, "toc.chapterTitle == chapterURL", in: "case_023/README.md")
        assertContains(expected, "chapterTitle equals chapterURL", in: "case_023/expected/toc_result.json")
    }

    private func read(_ relativePath: String, file: StaticString = #file, line: UInt = #line) -> String {
        let url = URL(fileURLWithPath: "\(repoRoot)/\(relativePath)")
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            XCTFail("freeze_gate: required file missing or unreadable: \(relativePath)", file: file, line: line)
            return ""
        }
        return text
    }

    private func assertContains(_ text: String, _ needle: String, in label: String,
                                file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(
            text.contains(needle),
            "freeze_gate: \(label) is missing required token: \"\(needle)\"",
            file: file,
            line: line
        )
    }

    private func assertNotContains(_ text: String, _ needle: String, in label: String,
                                   file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(
            text.contains(needle),
            "freeze_gate: \(label) must NOT contain forbidden token: \"\(needle)\"",
            file: file,
            line: line
        )
    }
}
