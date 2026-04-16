import Foundation
import ReaderCoreModels
import ReaderCoreProtocols
import ReaderCoreNetwork
import ReaderCoreParser

/// Core implementation of `SearchService`.
///
/// Chains `NetworkPolicyLayer` (fetch) → `NonJSParserEngine` (parse) and returns
/// typed `[SearchResultItem]`.  Callers receive only the `SearchService` protocol
/// type and need no knowledge of either layer.
public final class SearchServiceCoreImpl: SearchService, Sendable {

    private let networkLayer: NetworkPolicyLayer
    private let parser: NonJSParserEngine

    init(networkLayer: NetworkPolicyLayer, parser: NonJSParserEngine) {
        self.networkLayer = networkLayer
        self.parser       = parser
    }

    public func search(
        source: BookSource,
        query: SearchQuery
    ) async throws -> [SearchResultItem] {
        let response = try await networkLayer.performSearch(source: source, query: query)
        return try parser.parseSearchResponse(response.data, source: source, query: query)
    }
}
