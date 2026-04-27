import XCTest

/// POST_FIRST_REAL_PASS_STABILIZATION freeze gate.
///
/// Locks the case_022 verdict and document state in place. The gate must
/// fail loudly if a future change:
///   * removes the FIRST_REAL_PASS_CASE_ESTABLISHED marker,
///   * downgrades / rewords the PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES status,
///   * loses the structural numbers (659 chapters / 3465 chars) from the
///     persisted real-pass report,
///   * silently upgrades the regression report into a baseline claim, or
///   * detaches the plan document from the completed-case fact.
///
/// The gate intentionally does **not** fail on the documented known issues
/// (bookName 字数前缀 / author empty / toc title==url) — those are accepted
/// non-blocking trade-offs for this milestone.
final class Case022FirstRealPassFreezeGateTests: XCTestCase {
    private let repoRoot = "/Users/minliny/Documents/Reader-Core"

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
            file: file, line: line
        )
    }

    private func assertNotContains(_ text: String, _ needle: String, in label: String,
                                   file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(
            text.contains(needle),
            "freeze_gate: \(label) must NOT contain forbidden token: \"\(needle)\"",
            file: file, line: line
        )
    }

    // 1 + 2: case_022 metadata exists with the locked marker + status.
    func test_case022_metadata_locked() {
        let metadata = read("samples/real_world/non_js/case_022/metadata.yml")
        XCTAssertFalse(metadata.isEmpty, "freeze_gate: metadata.yml must exist and be non-empty")

        // marker == FIRST_REAL_PASS_CASE_ESTABLISHED
        assertContains(metadata, "FIRST_REAL_PASS_CASE_ESTABLISHED", in: "case_022/metadata.yml")
        assertContains(metadata, "marker: FIRST_REAL_PASS_CASE_ESTABLISHED", in: "case_022/metadata.yml")

        // status == PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES
        assertContains(metadata, "PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES", in: "case_022/metadata.yml")
        assertContains(metadata, "status: PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES", in: "case_022/metadata.yml")
    }

    // 3 + 4: first_real_pass_report.txt exists and carries the structural facts.
    func test_first_real_pass_report_locked() {
        let report = read("samples/real_world/non_js/case_022/first_real_pass_report.txt")
        XCTAssertFalse(report.isEmpty, "freeze_gate: first_real_pass_report.txt must exist and be non-empty")

        assertContains(report, "FIRST_REAL_PASS_CASE: YES", in: "first_real_pass_report.txt")

        // Each of the three pipeline stages must be PASS — count occurrences of "status: PASS".
        let passStageCount = report.components(separatedBy: "status: PASS").count - 1
        XCTAssertEqual(
            passStageCount, 3,
            "freeze_gate: first_real_pass_report.txt must record 3 stage PASSes (detail/toc/content), got \(passStageCount)"
        )

        // Frame the stage labels too — guards against accidental loss of any one stage section.
        assertContains(report, "detail:", in: "first_real_pass_report.txt")
        assertContains(report, "toc:", in: "first_real_pass_report.txt")
        assertContains(report, "content:", in: "first_real_pass_report.txt")

        // Structural numbers from the locked real run.
        assertContains(report, "chapter_count: 659", in: "first_real_pass_report.txt")
        assertContains(report, "content_length: 3465", in: "first_real_pass_report.txt")
    }

    // 5 + 6: regression_report.md must affirm the milestone and refuse the upgrade claim.
    func test_regression_report_aligned() {
        let report = read("samples/real_world/non_js/regression_report.md")
        XCTAssertFalse(report.isEmpty, "freeze_gate: regression_report.md must exist and be non-empty")

        assertContains(report, "FIRST_REAL_PASS_CASE_ESTABLISHED", in: "regression_report.md")
        assertContains(report, "case_022 = FIRST_REAL_PASS_CASE", in: "regression_report.md")
        assertContains(report, "NOT baseline ready", in: "regression_report.md")

        // Count may grow after case_022; baseline upgrade tokens must not.
        assertNotContains(report, "NON_JS_REAL_WORLD_REGRESSION_BASELINE_READY", in: "regression_report.md")
        assertNotContains(report, "BASELINE_READY", in: "regression_report.md")
    }

    // 7: PLAN.md must record case_022 completion + the locked status.
    func test_first_real_pass_plan_aligned() {
        let plan = read("docs/parser/FIRST_REAL_PASS_CASE_PLAN.md")
        XCTAssertFalse(plan.isEmpty, "freeze_gate: FIRST_REAL_PASS_CASE_PLAN.md must exist and be non-empty")

        assertContains(plan, "case_022 completed", in: "FIRST_REAL_PASS_CASE_PLAN.md")
        assertContains(plan, "PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES", in: "FIRST_REAL_PASS_CASE_PLAN.md")
    }

    // 8: known issues are explicitly carried in the documents as non-blocking,
    //    NOT flipped into a failure. The gate confirms the "known issue" framing
    //    survives — i.e. nobody silently treated them as regressions.
    func test_known_issues_are_documented_as_non_blocking() {
        let metadata = read("samples/real_world/non_js/case_022/metadata.yml")

        // The metadata's verification block should still anchor the three known
        // issues to the PASS verdict. We assert the issues exist as documented
        // facts; we do NOT assert that the parser output stopped exhibiting them.
        // (Per phase directive: do not patch parser, do not polish fields.)
        assertContains(metadata, "known_issue", in: "case_022/metadata.yml verification block")
        assertContains(metadata, "do_not_apply", in: "case_022/metadata.yml")
        assertContains(metadata, "parser_modification", in: "case_022/metadata.yml")
        assertContains(metadata, "author_or_name_field_polishing", in: "case_022/metadata.yml")

        // Even with the known issues present, the case-level status must remain
        // PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES — the gate fails if anyone flips
        // it to FAIL/REJECTED/etc. (already covered above by direct contains;
        // the assertion below is the explicit anti-flip guard).
        XCTAssertTrue(
            metadata.contains("status: PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES"),
            "freeze_gate: case_022 must remain PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES — known issues are non-blocking by directive"
        )
    }
}
