// CoreWiring.swift
// Constructs CoreAdapterDependencies and delegates to CoreServiceFactory.
// This is the single point in the shell that owns the dependency graph.

import Foundation
import ReaderCoreProtocols
import ReaderCoreServices
import ReaderPlatformAdapters

// MARK: - CoreWiring

/// Builds and owns the wired Core dependency graph for the iOS shell.
///
/// Usage:
/// ```swift
/// let wiring   = CoreWiring.live()
/// let services = wiring.services          // CoreServices from ReaderCoreServices
/// let results  = try await services.search.search(source: src, query: q)
/// ```
public struct CoreWiring: Sendable {

    /// The assembled adapter dependencies (http / storage / scheduler / logging).
    public let dependencies: CoreAdapterDependencies

    /// Service bundle vended by `CoreServiceFactory`.  Shell consumers receive
    /// protocol-typed members (`any SearchService`, etc.); no internal Core type
    /// leaks across this boundary.
    public let services: CoreServices

    // MARK: Lifecycle

    private init(dependencies: CoreAdapterDependencies, services: CoreServices) {
        self.dependencies = dependencies
        self.services     = services
    }

    // MARK: Factory

    /// Produces a live wiring backed by URLSession.
    public static func live() -> CoreWiring {
        let http  = HTTPAdapterFactory.makeDefault()
        let deps  = CoreAdapterDependencies(http: http)
        let svc   = CoreServiceFactory.make(dependencies: deps)
        return CoreWiring(dependencies: deps, services: svc)
    }

    /// Produces a fixture-backed wiring that replays pre-canned responses.
    /// Used by the CLI demo runner and unit tests.
    ///
    /// - Parameter adapter: A pre-configured mock adapter with enqueued responses.
    public static func fixture(adapter: any HTTPAdapterProtocol) -> CoreWiring {
        let deps = CoreAdapterDependencies(http: adapter)
        let svc  = CoreServiceFactory.make(dependencies: deps)
        return CoreWiring(dependencies: deps, services: svc)
    }
}
