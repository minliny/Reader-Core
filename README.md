# Reader-Core

Core compatibility kernel for the Reader project.

## Repository Role

Reader-Core is the independent Core main repo, extracted from Reader-iOS (Reader-for-iOS) via reverse split (2026-04-15).

## Contents

- `Core/` — Swift package (ReaderCore): parser, network, cache, JS renderer, models, protocols, platform adapters
- `samples/` — regression / compat / fixture / matrix / expected data
- `tools/` — smoke / regression / isolation / validators
- `Adapters/` — HTTP, Scheduler, Storage adapter specs
- `Platforms/` — Android, Windows, iOS platform architecture docs
- `.github/workflows/` — Core CI: core-swift-tests, fixture-toc-regression, policy-regression, sample smoke/isolation
- `Package.swift` (root) — SwiftPM URL resolution entry point
- `docs/` — API snapshot, architecture, decision engine, process, design, tooling

## Public Products (for Reader-iOS)

```swift
.package(url: "https://github.com/minliny/Reader-Core.git", exact: "0.1.0")
```

Available products: `ReaderCoreFoundation`, `ReaderCoreModels`, `ReaderCoreProtocols`,
`ReaderCoreParser`, `ReaderCoreNetwork`, `ReaderPlatformAdapters`, `ReaderCoreCache`, `ReaderCoreJSRenderer`

## Local Development

Reader-iOS uses local sibling path during development:
```swift
.package(path: "../Reader-Core")
```

## Stable Tag

`0.1.0` — first stable post-split release

## History

- Extracted from Reader-for-iOS (Reader-iOS) @ 4442610 (2026-04-15)
- Reverse split: Reader-iOS retains iOS shell; Core extracted here
