// LinuxSmokeRunner/linux_smoke_runner.swift
// Core NonJS smoke test logic — no @main here, just structs/functions.
// Imported by linux_smoke_main.swift.
import Foundation
import ReaderCoreModels
import ReaderCoreParser

struct SmokeSample {
    let id: String
    let bookSourcePath: String
    let searchHTMLPath: String
    let tocHTMLPath: String
    let contentHTMLPath: String
}

let allSamples: [SmokeSample] = [
    SmokeSample(
        id: "sample_001",
        bookSourcePath: "samples/booksources/p0_non_js/sample_001.json",
        searchHTMLPath:  "samples/fixtures/html/sample_001_search.html",
        tocHTMLPath:     "samples/fixtures/html/sample_001_toc.html",
        contentHTMLPath: "samples/fixtures/html/sample_001_content.html"
    ),
    SmokeSample(
        id: "sample_002",
        bookSourcePath: "samples/booksources/p0_non_js/sample_002.json",
        searchHTMLPath:  "samples/fixtures/html/sample_002_search.html",
        tocHTMLPath:     "samples/fixtures/html/sample_002_toc.html",
        contentHTMLPath: "samples/fixtures/html/sample_002_content.html"
    ),
    SmokeSample(
        id: "sample_003",
        bookSourcePath: "samples/booksources/p0_non_js/sample_003.json",
        searchHTMLPath:  "samples/fixtures/html/sample_003_search.html",
        tocHTMLPath:     "samples/fixtures/html/sample_003_toc.html",
        contentHTMLPath: "samples/fixtures/html/sample_003_content.html"
    ),
    SmokeSample(
        id: "sample_004",
        bookSourcePath: "samples/booksources/p0_non_js/sample_004.json",
        searchHTMLPath:  "samples/fixtures/html/sample_004_search.html",
        tocHTMLPath:     "samples/fixtures/html/sample_004_toc.html",
        contentHTMLPath: "samples/fixtures/html/sample_004_content.html"
    ),
    SmokeSample(
        id: "sample_005",
        bookSourcePath: "samples/booksources/p0_non_js/sample_005.json",
        searchHTMLPath:  "samples/fixtures/html/sample_005_search.html",
        tocHTMLPath:     "samples/fixtures/html/sample_005_toc.html",
        contentHTMLPath: "samples/fixtures/html/sample_005_content.html"
    ),
]

struct SmokeRunner {
    let repoRoot: String

    func rp(_ rel: String) -> String {
        return (URL(fileURLWithPath: repoRoot).appendingPathComponent(rel)).path
    }

    func readData(_ rel: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: rp(rel)))
    }

    func readStr(_ rel: String) throws -> String {
        try String(contentsOfFile: rp(rel), encoding: .utf8)
    }

    mutating func runAll() -> Bool {
        let engine = NonJSParserEngine()
        var allPassed = true

        for sample in allSamples {
            print("[\(sample.id)]")
            do {
                let bookSource = try JSONDecoder().decode(
                    BookSource.self, from: try readData(sample.bookSourcePath)
                )

                // Search
                let searchHTML = try readStr(sample.searchHTMLPath)
                let searchResults = try engine.parseSearchResponse(
                    Data(searchHTML.utf8),
                    source: bookSource,
                    query: SearchQuery(keyword: "fixture")
                )
                print("  search: \(searchResults.count) results")
                if searchResults.isEmpty {
                    print("  ERROR: no search results"); allPassed = false
                }

                // TOC
                let tocHTML = try readStr(sample.tocHTMLPath)
                let tocItems = try engine.parseTOCResponse(
                    Data(tocHTML.utf8),
                    source: bookSource,
                    detailURL: "http://fixture.local/book/1.html"
                )
                print("  toc: \(tocItems.count) chapters")
                if tocItems.isEmpty {
                    print("  ERROR: no TOC items"); allPassed = false
                }

                // Content
                let contentHTML = try readStr(sample.contentHTMLPath)
                let page = try engine.parseContentResponse(
                    Data(contentHTML.utf8),
                    source: bookSource,
                    chapterURL: "http://fixture.local/chapter/1.html"
                )
                let trimmed = page.content.trimmingCharacters(in: .whitespacesAndNewlines)
                print("  content: \(trimmed.count) chars")
                if trimmed.isEmpty {
                    print("  ERROR: content empty"); allPassed = false
                }

            } catch {
                print("  ERROR: \(error)"); allPassed = false
            }
        }

        print(allPassed ? "\nOVERALL: passed" : "\nOVERALL: FAILED")
        return allPassed
    }
}
