// CoreShellServices.swift — SUPERSEDED BY B-002
//
// This file previously contained a shell-side wiring of NetworkPolicyLayer +
// NonJSParserEngine into the SearchService / TOCService / ContentService contracts.
//
// B-002 has been resolved: Core now exposes `CoreServiceFactory.make(dependencies:)`
// in the `ReaderCoreServices` module, which performs the same wiring internally.
//
// The shell no longer needs this class.  `CoreWiring.swift` now delegates to
// `CoreServiceFactory` directly.  This file is intentionally left empty.
