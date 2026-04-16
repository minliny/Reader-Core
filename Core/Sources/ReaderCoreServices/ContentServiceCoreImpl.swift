import Foundation
import ReaderCoreModels
import ReaderCoreProtocols
import ReaderCoreNetwork
import ReaderCoreParser

/// Core implementation of `ContentService`.
///
/// Chains `NetworkPolicyLayer` (fetch) → `NonJSParserEngine` (parse) and returns
/// a typed `ContentPage`.
public final class ContentServiceCoreImpl: ContentService, Sendable {

    private let networkLayer: NetworkPolicyLayer
    private let parser: NonJSParserEngine

    init(networkLayer: NetworkPolicyLayer, parser: NonJSParserEngine) {
        self.networkLayer = networkLayer
        self.parser       = parser
    }

    public func fetchContent(
        source: BookSource,
        chapterURL: String
    ) async throws -> ContentPage {
        let response = try await networkLayer.performContent(source: source, chapterURL: chapterURL)
        return try parser.parseContentResponse(response.data, source: source, chapterURL: chapterURL)
    }
}
