# Platforms/iOS — Reader iOS Shell

**Phase:** B-001 complete — minimal integration loop  
**Gate blocker status:** B-001 RESOLVED / B-002 PENDING

---

## Purpose

This package is the minimal iOS host for Reader-Core.  It proves that:

1. Core modules can be imported and wired on iOS 15 / macOS 13
2. `CoreAdapterDependencies` can be constructed and injected
3. The search → toc → content loop runs end-to-end against fixture data
4. A real iOS SwiftUI entry point exists (prerequisite for M-IOS-1)

It is **not** a product UI.  No reading progress, no account management, no full BookSource catalogue.

---

## Package structure

```
Platforms/iOS/
  Package.swift
  Sources/
    ReaderIOSShell/
      CoreShellServices.swift   ← B-002 placeholder (search/toc/content wiring)
      CoreWiring.swift          ← constructs CoreAdapterDependencies
      SearchDemoViewModel.swift ← @MainActor ObservableObject driving the demo loop
      SearchDemoView.swift      ← SwiftUI list view (search results, toc, content)
      DemoRootView.swift        ← @main SwiftUI App entry point (iOS)
    ReaderIOSShellDemo/
      main.swift                ← macOS CLI runner (CI-friendly, no Xcode required)
```

---

## Running the demo

### CLI (macOS, no Xcode required)

```bash
cd Platforms/iOS
swift run ReaderIOSShellDemo
```

Expected output:

```
[search] running…
[search] PASS — 2 result(s): 天道图书馆
[toc] running… (http://fixture.local/book/1)
[toc] PASS — 3 chapter(s): 序章：开始
[content] running… (http://fixture.local/chapter/0)
[content] PASS — 夜已深，李珑独自伫立于图书馆最高处的露台上…

✅ Core connected — full search/toc/content loop verified (B-001 PASS)
```

### iOS Simulator / device

Open `Platforms/iOS/Package.swift` in Xcode, select the `ReaderIOSShell` library
scheme, run on any iOS 15+ simulator.  The `DemoRootView` app entry point will
display the demo loop result.

---

## Dependency notes

| Dependency | Source | Notes |
|---|---|---|
| `ReaderCoreModels` | `../../` | BookSource, SearchResultItem, TOCItem, ContentPage |
| `ReaderCoreProtocols` | `../../` | SearchService, TOCService, ContentService, CoreAdapterDependencies |
| `ReaderCoreParser` | `../../` | NonJSParserEngine (NullJSRenderingGate default) |
| `ReaderCoreNetwork` | `../../` | NetworkPolicyLayer |
| `ReaderPlatformAdapters` | `../../` | HTTPAdapterFactory, URLSessionHTTPClient, MockHTTPAdapter |

`MockHTTPAdapter` is imported from `ReaderPlatformAdapters` (production library).
This is a known issue tracked as **B-005** — the mock should move to a separate
test-support target.

---

## Open blockers

| ID | Description | Impact |
|---|---|---|
| B-002 | Core has no `CoreServiceFactory` | `CoreShellServices.swift` is a shell-side workaround; delete it once B-002 ships |
| B-003 | `CoreRuntimeDependencyInjection.makeDependencies()` always fatalErrors | Shell uses `HTTPAdapterFactory.makeDefault()` directly to avoid this |
| B-004 | `Adapters/HTTP/Package.swift` missing `.iOS(.v15)` | Shell depends on root `Core/Package.swift` which has correct platforms |
| B-005 | MockHTTPAdapter in production library | Acceptable for this phase; fix before any public release |
