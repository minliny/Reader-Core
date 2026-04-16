import Foundation
import ReaderCoreModels
import ReaderCoreProtocols
import ReaderCoreNetwork
import ReaderCoreParser

/// Core implementation of `TOCService`.
///
/// Chains `NetworkPolicyLayer` (fetch) → `NonJSParserEngine` (parse) and returns
/// typed `[TOCItem]`.
public final class TOCServiceCoreImpl: TOCService, Sendable {

    private let networkLayer: NetworkPolicyLayer
    private let parser: NonJSParserEngine

    init(networkLayer: NetworkPolicyLayer, parser: NonJSParserEngine) {
        self.networkLayer = networkLayer
        self.parser       = parser
    }

    public func fetchTOC(
        source: BookSource,
        detailURL: String
    ) async throws -> [TOCItem] {
        let response = try await networkLayer.performTOC(source: source, detailURL: detailURL)
        return try parser.parseTOCResponse(response.data, source: source, detailURL: detailURL)
    }
}
