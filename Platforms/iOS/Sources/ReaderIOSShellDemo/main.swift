// main.swift — ReaderIOSShellDemo
// macOS CLI executable that validates the Core integration loop without Xcode.
//
// Run from Platforms/iOS/:
//   swift run ReaderIOSShellDemo
//
// Exit codes:
//   0  — loop verified (all three phases passed)
//   1  — loop failed (see stderr)

import Foundation
import ReaderCoreModels
import ReaderCoreProtocols
import ReaderCoreParser
import ReaderCoreNetwork
import ReaderPlatformAdapters

// ─────────────────────────────────────────────
// MARK: Fixture data
// ─────────────────────────────────────────────

let searchHTML = """
<html><body>
<div class="item">天道图书馆|http://fixture.local/book/1|佚名</div>
<div class="item">星辰大海|http://fixture.local/book/2|无名氏</div>
</body></html>
"""

let tocHTML = """
<html><body>
<div class="chapter">序章：开始|http://fixture.local/chapter/0</div>
<div class="chapter">第一章：觉醒|http://fixture.local/chapter/1</div>
<div class="chapter">第二章：试炼|http://fixture.local/chapter/2</div>
</body></html>
"""

let contentHTML = """
<html><body>
<div class="content">夜已深，李珑独自伫立于图书馆最高处的露台上，俯瞰着整座城市星星点点的灯火。风带着凉意掠过，将他的衣角轻轻吹起。</div>
</body></html>
"""

// ─────────────────────────────────────────────
// MARK: Demo source (matches sample_001.json)
// ─────────────────────────────────────────────

let demoSource = BookSource(
    bookSourceName: "Demo-Fixture-Source",
    bookSourceUrl:  "http://fixture.local",
    searchUrl:      "http://fixture.local/search?q={{key}}",
    ruleSearch:     "css:.item",
    ruleToc:        "css:.chapter",
    ruleContent:    "css:.content",
    enabled:        true
)

// ─────────────────────────────────────────────
// MARK: Run loop
// ─────────────────────────────────────────────

func run() async -> Int32 {
    let mock = MockHTTPAdapter()
    await mock.enqueue(statusCode: 200,
                       headers: ["Content-Type": "text/html"],
                       body: searchHTML)
    await mock.enqueue(statusCode: 200,
                       headers: ["Content-Type": "text/html"],
                       body: tocHTML)
    await mock.enqueue(statusCode: 200,
                       headers: ["Content-Type": "text/html"],
                       body: contentHTML)

    let networkLayer = NetworkPolicyLayer(httpClient: mock)
    let parser       = NonJSParserEngine()

    do {
        // ── Search ──────────────────────────────────────────────────────
        print("[search] running…")
        let searchQuery = SearchQuery(keyword: "天道")
        let searchResponse = try await networkLayer.performSearch(source: demoSource, query: searchQuery)
        let results = try parser.parseSearchResponse(searchResponse.data, source: demoSource, query: searchQuery)
        guard !results.isEmpty else {
            fputs("[search] FAIL — no results\n", stderr); return 1
        }
        print("[search] PASS — \(results.count) result(s): \(results[0].title)")

        // ── TOC ─────────────────────────────────────────────────────────
        let detailURL = results[0].detailURL
        print("[toc] running… (\(detailURL))")
        let tocResponse = try await networkLayer.performTOC(source: demoSource, detailURL: detailURL)
        let chapters = try parser.parseTOCResponse(tocResponse.data, source: demoSource, detailURL: detailURL)
        guard !chapters.isEmpty else {
            fputs("[toc] FAIL — no chapters\n", stderr); return 1
        }
        print("[toc] PASS — \(chapters.count) chapter(s): \(chapters[0].title)")

        // ── Content ─────────────────────────────────────────────────────
        let chapterURL = chapters[0].chapterURL
        print("[content] running… (\(chapterURL))")
        let contentResponse = try await networkLayer.performContent(source: demoSource, chapterURL: chapterURL)
        let page = try parser.parseContentResponse(contentResponse.data, source: demoSource, chapterURL: chapterURL)
        guard !page.content.isEmpty else {
            fputs("[content] FAIL — empty content\n", stderr); return 1
        }
        print("[content] PASS — \(page.content.prefix(60))…")

        // ── Summary ─────────────────────────────────────────────────────
        print("\n✅ Core connected — full search/toc/content loop verified (B-001 PASS)")
        return 0

    } catch {
        fputs("\n❌ Demo loop failed: \(error)\n", stderr)
        return 1
    }
}

// ─────────────────────────────────────────────
// MARK: Entry point
// ─────────────────────────────────────────────

let exitCode = await run()
exit(exitCode)
