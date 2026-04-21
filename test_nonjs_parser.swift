#!/usr/bin/env swift

import Foundation
import ReaderCoreModels
import ReaderCoreParser

// Simple test script to verify NonJSParserEngine functionality
// Usage: swift test_nonjs_parser.swift <sample_number>

func testSample(_ sampleNumber: String) throws {
    let repoRoot = FileManager.default.currentDirectoryPath
    
    func rp(_ rel: String) -> String {
        URL(fileURLWithPath: repoRoot).appendingPathComponent(rel).path
    }
    
    func readStr(_ rel: String) throws -> String {
        try String(contentsOfFile: rp(rel), encoding: .utf8)
    }
    
    func readData(_ rel: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: rp(rel)))
    }
    
    // Load assets
    let bookSource = try JSONDecoder().decode(
        BookSource.self,
        from: try readData("samples/booksources/p0_non_js/sample_\(sampleNumber).json")
    )
    let searchHTML  = try readStr("samples/fixtures/html/sample_\(sampleNumber)_search.html")
    let tocHTML     = try readStr("samples/fixtures/html/sample_\(sampleNumber)_toc.html")
    let contentHTML = try readStr("samples/fixtures/html/sample_\(sampleNumber)_content.html")
    
    // Load expected results
    struct ExpectedSearchFile: Decodable {
        struct Body: Decodable {
            struct Item: Decodable {
                let title: String
                let detailURL: String
            }
            let resultCount: Int
            let items: [Item]
        }
        let expected: Body
    }
    
    struct ExpectedTocFile: Decodable {
        struct Body: Decodable {
            struct Chapter: Decodable {
                let chapterTitle: String
                let chapterURL: String
                let chapterIndex: Int
            }
            let chapterCount: Int
            let chapters: [Chapter]
        }
        let expected: Body
    }
    
    struct ExpectedContentFile: Decodable {
        struct Body: Decodable {
            let contentNonEmpty: Bool
            let content: String
        }
        let expected: Body
    }
    
    let expSearch  = try JSONDecoder().decode(ExpectedSearchFile.self,  from: try readData("samples/expected/search/sample_\(sampleNumber).json"))
    let expToc     = try JSONDecoder().decode(ExpectedTocFile.self,     from: try readData("samples/expected/toc/sample_\(sampleNumber).json"))
    let expContent = try JSONDecoder().decode(ExpectedContentFile.self, from: try readData("samples/expected/content/sample_\(sampleNumber).json"))
    
    let engine = NonJSParserEngine()
    
    // Test Search
    print("=== Testing Sample \(sampleNumber) ===")
    print("Testing Search...")
    do {
        let query = SearchQuery(keyword: "fixture")
        let actualSearch = try engine.parseSearchResponse(
            Data(searchHTML.utf8), source: bookSource, query: query
        )
        let countOK = actualSearch.count == expSearch.expected.resultCount
        let itemsOK = actualSearch.count == expSearch.expected.items.count &&
            zip(actualSearch, expSearch.expected.items).allSatisfy {
                $0.title == $1.title && $0.detailURL == $1.detailURL
            }
        if countOK && itemsOK {
            print("✓ Search: PASSED")
        } else {
            print("✗ Search: FAILED - OUTPUT_MISMATCH")
            print("  Expected: \(expSearch.expected.resultCount) items")
            print("  Actual: \(actualSearch.count) items")
        }
    } catch {
        print("✗ Search: FAILED - SEARCH_FAILED")
        print("  Error: \(error)")
    }
    
    // Test TOC
    print("Testing TOC...")
    do {
        let actualToc = try engine.parseTOCResponse(
            Data(tocHTML.utf8),
            source: bookSource,
            detailURL: "http://fixture\(sampleNumber).local/book/1.html"
        )
        let countOK = actualToc.count == expToc.expected.chapterCount
        let itemsOK = actualToc.count == expToc.expected.chapters.count &&
            zip(actualToc, expToc.expected.chapters).allSatisfy {
                $0.chapterTitle == $1.chapterTitle && $0.chapterURL == $1.chapterURL
            }
        if countOK && itemsOK {
            print("✓ TOC: PASSED")
        } else {
            print("✗ TOC: FAILED - OUTPUT_MISMATCH")
            print("  Expected: \(expToc.expected.chapterCount) chapters")
            print("  Actual: \(actualToc.count) chapters")
        }
    } catch {
        print("✗ TOC: FAILED - TOC_FAILED")
        print("  Error: \(error)")
    }
    
    // Test Content
    print("Testing Content...")
    do {
        let page = try engine.parseContentResponse(
            Data(contentHTML.utf8),
            source: bookSource,
            chapterURL: "http://fixture\(sampleNumber).local/chapter/1.html"
        )
        let actualContent = page.content
        if !actualContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("✓ Content: PASSED")
            print("  Content preview: \(actualContent.prefix(80))...")
        } else {
            print("✗ Content: FAILED - CONTENT_FAILED")
        }
    } catch {
        print("✗ Content: FAILED - CONTENT_FAILED")
        print("  Error: \(error)")
    }
    
    print("==================================\n")
}

// Run tests for samples 002-005
for sample in ["002", "003", "004", "005"] {
    do {
        try testSample(sample)
    } catch {
        print("Error testing sample \(sample): \(error)")
        print("==================================\n")
    }
}