// tools/smoke/main.swift
// Linux-compatible smoke runner (Swift 5.9 top-level main syntax).
// No @main attribute needed — uses top-level main() as entry point.
// Usage (WSL):
//   export PATH=~/swift/usr/bin:/usr/bin:/bin:$PATH
//   cd /path/to/Reader-Core
//   swift build --package-path Core --configuration release --target ReaderCoreParser
//   swiftc -I Core/.build/x86_64-unknown-linux-gnu/release \
//          tools/smoke/main.swift -o /tmp/smoke && /tmp/smoke
//
// GitHub Actions (wsl-nonjs-smoke.yml) uses the same pattern on ubuntu-latest + WSL2.

import Foundation
import ReaderCoreModels
import ReaderCoreParser

// ── Config ─────────────────────────────────────────────────────────────────

let samples = [
    ("sample_001", "samples/booksources/p0_non_js/sample_001.json",
     "samples/fixtures/html/sample_001_search.html",
     "samples/fixtures/html/sample_001_toc.html",
     "samples/fixtures/html/sample_001_content.html"),
]

// ── Helpers ─────────────────────────────────────────────────────────────────

func rp(_ rel: String) -> String {
    URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(rel).path
}

func readData(_ rel: String) -> Data {
    try! Data(contentsOf: URL(fileURLWithPath: rp(rel)))
}

func readStr(_ rel: String) -> String {
    try! String(contentsOfFile: rp(rel), encoding: .utf8)
}

// ── Entry point ───────────────────────────────────────────────────────────────

main() {
    let engine = NonJSParserEngine()
    var allPassed = true

    for (id, bsPath, searchPath, tocPath, contentPath) in samples {
        print("[\(id)]")
        do {
            let bookSource = try JSONDecoder().decode(BookSource.self, from: readData(bsPath))

            // Search
            let searchHTML = readStr(searchPath)
            let searchResults = try engine.parseSearchResponse(
                Data(searchHTML.utf8), source: bookSource, query: SearchQuery(keyword: "fixture")
            )
            print("  search: \(searchResults.count) results")
            if searchResults.isEmpty { print("  ERROR: no search results"); allPassed = false }

            // TOC
            let tocHTML = readStr(tocPath)
            let tocItems = try engine.parseTOCResponse(
                Data(tocHTML.utf8), source: bookSource, detailURL: "http://fixture.local/book/1.html"
            )
            print("  toc: \(tocItems.count) chapters")
            if tocItems.isEmpty { print("  ERROR: no TOC items"); allPassed = false }

            // Content
            let contentHTML = readStr(contentPath)
            let page = try engine.parseContentResponse(
                Data(contentHTML.utf8), source: bookSource, chapterURL: "http://fixture.local/chapter/1.html"
            )
            let trimmed = page.content.trimmingCharacters(in: .whitespacesAndNewlines)
            print("  content: \(trimmed.count) chars")
            if trimmed.isEmpty { print("  ERROR: content empty"); allPassed = false }

        } catch {
            print("  ERROR: \(error)")
            allPassed = false
        }
    }

    print(allPassed ? "\nOVERALL: passed" : "\nOVERALL: FAILED")
    if !allPassed { exit(1) }
}
