# Reader-Core Project Status

## Repository Role

Reader-Core is the independent Core compatibility kernel repo, extracted from Reader-for-iOS (now Reader-iOS) via reverse split execution (2026-04-14).

## Reverse Split Origin

- Source repo: Reader-for-iOS (now Reader-iOS, `github.com/minliny/Reader-for-iOS`)
- Extraction date: 2026-04-14
- Extraction direction: Core assets pulled OUT of Reader-for-iOS → Reader-Core

## Assets In This Repo

- `Core/` — Swift package (ReaderCore)
- `samples/` — regression / compat / fixture / matrix / expected
- `tools/` — smoke / regression / isolation / validators
- `scripts/` — Core tooling scripts
- `.github/workflows/` — Core CI (core-swift-tests, fixture-toc-regression, policy-regression, sample smoke/isolation, auto-sample-extractor)
- `docs/API_SNAPSHOT/`, `docs/architecture/`, `docs/decision_engine/`, `docs/process/`, `docs/FIXTURE_INFRA_SPEC.md`, `docs/TOOLING_BACKLOG.md`
- `Package.swift` (root) — enables SwiftPM URL resolution from Reader-iOS

## Current Dependency Direction

Reader-iOS → Reader-Core public products only

## Stable Tag

`0.1.0` — pinned exact version in Reader-iOS `iOS/Package.swift`

## State Flags

```yaml
reader_core_repo_initialized_locally: true
reverse_split_direction_applied: true
physical_core_extraction_complete: true
```

## Post-Extract Followup

- Tag next Core release when public surface changes
- Reader-iOS upgrades from `exact: "0.1.0"` to `upToNextMinor` after CI baseline confirmed
