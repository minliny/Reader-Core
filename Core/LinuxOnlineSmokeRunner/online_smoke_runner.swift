// LinuxOnlineSmokeRunner/online_smoke_runner.swift
// Online NonJS smoke test — fetches real pages and verifies parsing.
import Foundation
import ReaderCoreModels
import ReaderCoreParser
import ReaderCoreProtocols
import ReaderPlatformAdapters

struct OnlineSmokeRunner {
    let repoRoot: String

    func rp(_ rel: String) -> String {
        return (URL(fileURLWithPath: repoRoot).appendingPathComponent(rel)).path
    }

    func readData(_ rel: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: rp(rel)))
    }

    @MainActor
    func runOnline(bookSourcePath: String) async -> Bool {
        let engine = NonJSParserEngine()
        let httpClient = MinimalHTTPAdapter()
        var allPassed = true

        print("[online: \(bookSourcePath)]")
        do {
            let bookSource = try JSONDecoder().decode(
                BookSource.self, from: try readData(bookSourcePath)
            )
            print("  json: loaded")

            // Search
            if let searchUrl = bookSource.searchUrl, !searchUrl.isEmpty, let ruleSearch = bookSource.ruleSearch, !ruleSearch.isEmpty {
                let searchURLStr = buildSearchURL(searchUrl, query: "test")
                print("  search_url: \(searchURLStr)")
                do {
                    let request = HTTPRequest(url: searchURLStr, method: "GET")
                    let response = try await httpClient.send(request)
                    print("  search_status: \(response.statusCode)")
                    if response.statusCode == 200 {
                        let results = try engine.parseSearchResponse(
                            response.data,
                            source: bookSource,
                            query: SearchQuery(keyword: "test")
                        )
                        print("  search: \(results.count) results")
                        if results.isEmpty {
                            print("  ERROR: no search results")
                        }
                    } else {
                        print("  ERROR: non-200 response")
                        allPassed = false
                    }
                } catch {
                    print("  search_error: \(error.localizedDescription)")
                    allPassed = false
                }
            } else {
                print("  search: skipped (no searchUrl or ruleSearch)")
            }

            // TOC
            if let ruleToc = bookSource.ruleToc, !ruleToc.isEmpty {
                print("  toc: skipped (no detail URL)")
            } else {
                print("  toc: skipped (no ruleToc)")
            }

            // Content
            if let ruleContent = bookSource.ruleContent, !ruleContent.isEmpty {
                print("  content: skipped (no chapter URL)")
            } else {
                print("  content: skipped (no ruleContent)")
            }

        } catch {
            print("  ERROR: \(error.localizedDescription)")
            allPassed = false
        }

        print(allPassed ? "\nOVERALL: passed" : "\nOVERALL: FAILED")
        return allPassed
    }

    private func buildSearchURL(_ urlTemplate: String, query: String) -> String {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return urlTemplate.replacingOccurrences(of: "{{key}}", with: encodedQuery)
    }
}