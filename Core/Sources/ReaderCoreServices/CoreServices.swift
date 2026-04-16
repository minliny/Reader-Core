import Foundation
import ReaderCoreProtocols

// MARK: - CoreServices

/// Typed aggregate of the three reading-flow services vended by `CoreServiceFactory`.
///
/// iOS Shell usage:
/// ```swift
/// let services = CoreServiceFactory.make(dependencies: deps)
/// let results  = try await services.search.search(source: src, query: q)
/// let chapters = try await services.toc.fetchTOC(source: src, detailURL: url)
/// let page     = try await services.content.fetchContent(source: src, chapterURL: chURL)
/// ```
public struct CoreServices: Sendable {

    /// Concrete search capability backed by `NetworkPolicyLayer` + `NonJSParserEngine`.
    public let search: any SearchService

    /// Concrete TOC capability backed by `NetworkPolicyLayer` + `NonJSParserEngine`.
    public let toc: any TOCService

    /// Concrete content capability backed by `NetworkPolicyLayer` + `NonJSParserEngine`.
    public let content: any ContentService

    /// Memberwise initialiser — internal so only `CoreServiceFactory` vends instances.
    init(
        search: any SearchService,
        toc: any TOCService,
        content: any ContentService
    ) {
        self.search  = search
        self.toc     = toc
        self.content = content
    }
}
