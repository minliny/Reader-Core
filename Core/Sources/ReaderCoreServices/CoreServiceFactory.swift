import Foundation
import ReaderCoreProtocols
import ReaderCoreNetwork
import ReaderCoreParser

// MARK: - CoreServiceFactory

/// Single public entry point for obtaining Core reading-flow services.
///
/// Accepts a `CoreAdapterDependencies` bag (built by the shell) and returns
/// a `CoreServices` aggregate whose members satisfy `SearchService`, `TOCService`,
/// and `ContentService`.
///
/// The shell only needs to import `ReaderCoreServices`; it has no visibility
/// into `NetworkPolicyLayer`, `NonJSParserEngine`, or any other internal type.
///
/// ## New public API
/// - `CoreServiceFactory` (enum namespace, no stored state)
/// - `CoreServiceFactory.make(dependencies:) -> CoreServices`
/// - `CoreServices` (struct, three protocol-typed properties)
///
/// ## Freeze impact
/// Additive only.  No existing frozen symbol is modified.
/// `CoreServices` and `CoreServiceFactory` are new top-level public types in the
/// new `ReaderCoreServices` module — they do not appear in any existing module's
/// public surface.
///
/// ## Acceptance
/// - `swift build --target ReaderCoreServices` passes
/// - `swift test --filter ReaderCoreServicesTests` passes
/// - iOS Shell `CoreWiring` replaces `CoreShellServices` with a one-line call to
///   `CoreServiceFactory.make(dependencies:)`
public enum CoreServiceFactory {

    /// Builds a fully wired `CoreServices` bundle from adapter dependencies.
    ///
    /// Internally constructs one shared `NetworkPolicyLayer` and one shared
    /// `NonJSParserEngine` (with `NullJSRenderingGate`) that are reused across
    /// all three service implementations.
    ///
    /// - Parameter dependencies: Adapter bag provided by the hosting shell.
    ///   Only `dependencies.http` is required; storage/scheduler/logger are
    ///   reserved for future phases.
    /// - Returns: A `CoreServices` value ready for immediate use.
    public static func make(dependencies: CoreAdapterDependencies) -> CoreServices {
        let networkLayer = NetworkPolicyLayer(httpClient: dependencies.http)
        let parser       = NonJSParserEngine()   // NullJSRenderingGate by default
        return CoreServices(
            search:  SearchServiceCoreImpl(networkLayer: networkLayer, parser: parser),
            toc:     TOCServiceCoreImpl(networkLayer: networkLayer, parser: parser),
            content: ContentServiceCoreImpl(networkLayer: networkLayer, parser: parser)
        )
    }
}
