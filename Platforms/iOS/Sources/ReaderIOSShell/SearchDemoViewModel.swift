// SearchDemoViewModel.swift
// Drives the three-phase demo loop: search → toc → content.
// All Core calls go through CoreServices (via CoreServiceFactory / B-002 resolved).

import Foundation
import ReaderCoreModels
import ReaderCoreProtocols
import ReaderCoreServices

// MARK: - Phase

/// Represents the current stage of the demo loop.
public enum DemoPhase: Equatable {
    case idle
    case running(step: String)
    case done
    case failed(String)
}

// MARK: - SearchDemoViewModel

@MainActor
public final class SearchDemoViewModel: ObservableObject {

    // MARK: Published state

    @Published public var phase: DemoPhase = .idle
    @Published public var searchResults: [SearchResultItem] = []
    @Published public var tocItems: [TOCItem] = []
    @Published public var contentPage: ContentPage? = nil
    @Published public var log: [String] = []

    // MARK: Dependencies

    private let services: CoreServices
    private let source: BookSource

    // MARK: Init

    public init(services: CoreServices, source: BookSource) {
        self.services = services
        self.source   = source
    }

    // MARK: Actions

    /// Runs the full search → toc → content demo path.
    /// Driven by fixture data; no real network required.
    public func runDemo(keyword: String = "天道") async {
        log.removeAll()
        searchResults.removeAll()
        tocItems.removeAll()
        contentPage = nil

        // ── Step 1: Search ──────────────────────────────────────────────
        phase = .running(step: "search")
        appendLog("▶ search("\(keyword)")")
        let query = SearchQuery(keyword: keyword)
        do {
            let results = try await services.search.search(source: source, query: query)
            searchResults = results
            appendLog("✔ search → \(results.count) result(s)")
            if results.isEmpty {
                phase = .failed("Search returned no results.")
                return
            }
        } catch {
            phase = .failed("search: \(error)")
            return
        }

        // ── Step 2: TOC ─────────────────────────────────────────────────
        let detailURL = searchResults[0].detailURL
        phase = .running(step: "toc")
        appendLog("▶ toc(\(detailURL))")
        do {
            let chapters = try await services.toc.fetchTOC(source: source, detailURL: detailURL)
            tocItems = chapters
            appendLog("✔ toc → \(chapters.count) chapter(s)")
            if chapters.isEmpty {
                phase = .failed("TOC returned no chapters.")
                return
            }
        } catch {
            phase = .failed("toc: \(error)")
            return
        }

        // ── Step 3: Content ─────────────────────────────────────────────
        let chapterURL = tocItems[0].chapterURL
        phase = .running(step: "content")
        appendLog("▶ content(\(chapterURL))")
        do {
            let page = try await services.content.fetchContent(source: source, chapterURL: chapterURL)
            contentPage = page
            appendLog("✔ content → \(page.content.prefix(60))…")
        } catch {
            phase = .failed("content: \(error)")
            return
        }

        phase = .done
        appendLog("✅ Core connected — full search/toc/content loop verified")
    }

    // MARK: Helpers

    private func appendLog(_ message: String) {
        log.append(message)
    }
}
