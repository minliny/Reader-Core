// DemoRootView.swift
// Top-level SwiftUI scene entry point for the iOS shell.
// Wires CoreWiring (fixture mode) → SearchDemoViewModel → SearchDemoView.

import SwiftUI
import ReaderCoreModels
import ReaderCoreProtocols
import ReaderPlatformAdapters

// MARK: - DemoRootView

/// Root view of the iOS Shell demo app.
///
/// Uses a fixture-backed MockHTTPAdapter so the loop runs without a real
/// network.  Replace `CoreWiring.fixture(adapter:)` with `CoreWiring.live()`
/// when testing against a live source.
public struct DemoRootView: View {

    // MARK: State

    @StateObject private var vm: SearchDemoViewModel

    // MARK: Init

    public init() {
        let mock = MockHTTPAdapter()
        DemoRootView.enqueueFixtures(into: mock)
        let wiring = CoreWiring.fixture(adapter: mock)
        let source = DemoRootView.fixtureSource
        _vm = StateObject(wrappedValue: SearchDemoViewModel(services: wiring.services, source: source))
    }

    // MARK: Body

    public var body: some View {
        SearchDemoView(vm: vm)
    }

    // MARK: - Fixture helpers

    /// Demo BookSource matching samples/booksources/p0_non_js/sample_001.json.
    static var fixtureSource: BookSource {
        BookSource(
            bookSourceName: "Demo-Fixture-Source",
            bookSourceUrl:  "http://fixture.local",
            searchUrl:      "http://fixture.local/search?q={{key}}",
            ruleSearch:     "css:.item",
            ruleToc:        "css:.chapter",
            ruleContent:    "css:.content",
            enabled:        true
        )
    }

    /// Pre-loads three fixture responses (search → toc → content) into the mock adapter.
    ///
    /// HTML format matches NonJSRuleScheduler's class-based CSS extractor:
    ///   `<div class="{selector}">field1|field2|…</div>`
    static func enqueueFixtures(into mock: MockHTTPAdapter) {
        // Search response — pipe-separated: title|detailURL|author
        let searchHTML = """
        <html><body>
        <div class="item">天道图书馆|http://fixture.local/book/1|佚名</div>
        <div class="item">星辰大海|http://fixture.local/book/2|无名氏</div>
        </body></html>
        """

        // TOC response — pipe-separated: title|chapterURL
        let tocHTML = """
        <html><body>
        <div class="chapter">序章：开始|http://fixture.local/chapter/0</div>
        <div class="chapter">第一章：觉醒|http://fixture.local/chapter/1</div>
        <div class="chapter">第二章：试炼|http://fixture.local/chapter/2</div>
        </body></html>
        """

        // Content response — plain text inside the selector
        let contentHTML = """
        <html><body>
        <div class="content">夜已深，李珑独自伫立于图书馆最高处的露台上，俯瞰着整座城市星星点点的灯火。风带着凉意掠过，将他的衣角轻轻吹起。</div>
        </body></html>
        """

        Task {
            await mock.enqueue(statusCode: 200, headers: ["Content-Type": "text/html"],
                               body: searchHTML)
            await mock.enqueue(statusCode: 200, headers: ["Content-Type": "text/html"],
                               body: tocHTML)
            await mock.enqueue(statusCode: 200, headers: ["Content-Type": "text/html"],
                               body: contentHTML)
        }
    }
}

// MARK: - App entry point (iOS / macOS Catalyst)

#if os(iOS)
@main
struct ReaderIOSShellApp: App {
    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}
#endif
