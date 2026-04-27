import XCTest
@testable import ReaderCoreParser
import ReaderCoreModels

/// Phase: PRE_FIRST_REAL_PASS_CASE
///
/// Drives the V3 NonJSParserEngine against the freshly-fetched real
/// sudugu.org HTML for case_022 across the three pipeline stages
/// detail → toc → content. Pass gate (per phase spec):
///   - detail   : tocURL non-empty
///   - toc      : at least one TOCItem with non-empty title and URL
///   - content  : content body length > 100 chars
final class Case022FirstRealPassTests: XCTestCase {
    private let caseRoot = "/Users/minliny/Documents/Reader-Core/samples/real_world/non_js/case_022"

    private func loadSource() throws -> BookSource {
        let url = URL(fileURLWithPath: "\(caseRoot)/booksource.json")
        return try JSONDecoder().decode(BookSource.self, from: Data(contentsOf: url))
    }

    private func loadFixture(_ name: String) throws -> Data {
        let url = URL(fileURLWithPath: "\(caseRoot)/fixtures/\(name).html")
        return try Data(contentsOf: url)
    }

    func testFirstRealPassCase022() throws {
        let engine = NonJSParserEngine()
        let source = try loadSource()

        let detailURL = source.bookSourceUrl.flatMap { $0.isEmpty ? nil : "\($0.trimmingTrailingSlash())/51/" } ?? "https://www.sudugu.org/51/"

        var detailStatus = "FAIL"
        var detailExtracted: [String: String] = [:]
        var detailFailureReason: String?

        var tocStatus = "FAIL"
        var tocChapterCount = 0
        var tocFailureReason: String?

        var contentStatus = "FAIL"
        var contentLength = 0
        var contentFailureReason: String?

        // Stage 1: detail
        do {
            let data = try loadFixture("detail")
            let info = try engine.parseBookInfoResponse(data, source: source, detailURL: detailURL)
            detailExtracted = [
                "bookName": info.bookName,
                "author": info.author,
                "tocUrl": info.tocURL
            ]
            if info.tocURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                detailFailureReason = "tocUrl_empty"
            } else {
                detailStatus = "PASS"
            }
        } catch {
            detailFailureReason = "exception: \(error)"
        }

        // Stage 2: toc
        do {
            let data = try loadFixture("toc")
            let toc = try engine.parseTOCResponse(data, source: source, detailURL: detailURL)
            tocChapterCount = toc.count
            let firstNonEmpty = toc.first { !$0.chapterTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !$0.chapterURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if firstNonEmpty == nil {
                tocFailureReason = "no_chapter_with_nonempty_title_and_url"
            } else if toc.isEmpty {
                tocFailureReason = "chapter_list_empty"
            } else {
                tocStatus = "PASS"
            }
        } catch {
            tocFailureReason = "exception: \(error)"
        }

        // Stage 3: content
        do {
            let data = try loadFixture("content")
            let page = try engine.parseContentResponse(data, source: source, chapterURL: "https://www.sudugu.org/51/3612068.html")
            contentLength = page.content.count
            if contentLength > 100 {
                contentStatus = "PASS"
            } else {
                contentFailureReason = "content_length_le_100 (got \(contentLength))"
            }
        } catch {
            contentFailureReason = "exception: \(error)"
        }

        // Emit a structured report on stdout in the format requested by the phase spec.
        var lines: [String] = []
        lines.append("============ FIRST_REAL_PASS_CASE_REPORT ============")
        lines.append("case: case_022")
        lines.append("")
        lines.append("detail:")
        lines.append("  status: \(detailStatus)")
        lines.append("  extracted_fields:")
        for key in ["bookName", "author", "tocUrl"] {
            let v = detailExtracted[key] ?? "<missing>"
            lines.append("    \(key): \(v)")
        }
        if let reason = detailFailureReason {
            lines.append("  failure_reason: \(reason)")
        }
        lines.append("")
        lines.append("toc:")
        lines.append("  status: \(tocStatus)")
        lines.append("  chapter_count: \(tocChapterCount)")
        if let reason = tocFailureReason {
            lines.append("  failure_reason: \(reason)")
        }
        lines.append("")
        lines.append("content:")
        lines.append("  status: \(contentStatus)")
        lines.append("  content_length: \(contentLength)")
        if let reason = contentFailureReason {
            lines.append("  failure_reason: \(reason)")
        }
        lines.append("")

        let allPass = (detailStatus == "PASS" && tocStatus == "PASS" && contentStatus == "PASS")
        lines.append("final:")
        lines.append("  FIRST_REAL_PASS_CASE: \(allPass ? "YES" : "NO")")
        if !allPass {
            var reasons: [String] = []
            if detailStatus != "PASS" { reasons.append("detail:\(detailFailureReason ?? "unknown")") }
            if tocStatus != "PASS" { reasons.append("toc:\(tocFailureReason ?? "unknown")") }
            if contentStatus != "PASS" { reasons.append("content:\(contentFailureReason ?? "unknown")") }
            lines.append("  failure_reason: \(reasons.joined(separator: " | "))")
        }
        lines.append("=====================================================")

        let report = lines.joined(separator: "\n")
        print(report)

        // Persist the report next to the case for inspection.
        let reportURL = URL(fileURLWithPath: "\(caseRoot)/first_real_pass_report.txt")
        try? report.data(using: .utf8)?.write(to: reportURL)

        XCTAssertTrue(allPass, "FIRST_REAL_PASS_CASE not satisfied:\n\(report)")
    }
}

private extension String {
    func trimmingTrailingSlash() -> String {
        var s = self
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }
}
