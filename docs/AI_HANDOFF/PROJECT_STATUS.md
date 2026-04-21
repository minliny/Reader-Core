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
- `docs/AI_GOVERNANCE/` — minimum Prompt / AI governance baseline
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

## Parser V2 Baseline (2026-04-20)

NonJSRuleScheduler simple selector grammar unified with formal AST.

### Supported Selectors

| Selector | AST Case |
|----------|----------|
| `.class` | `byClass(String)` |
| `#id` | `byId(String)` |
| `tag` | `byTag(String)` |
| `tag.class` | `byTagAndClass(tag: String, className: String)` |

### Not Supported (explicitly rejected, no fallback)

- `tag#id`
- `.a.b` (multi-class)
- `tag.class.other`
- descendant selector (space)
- attribute selector `[attr]`
- pseudo selector `:`
- combinator `>`

### Trimming Grammar

`!` suffix is independent grammar. Illegal suffix (negative index, invalid chars) does NOT activate trimming.

### Test Coverage

- `NonJSTagClassRegressionTests`: 5 tests (selector behavior)
- `SimpleSelectorGrammarTests`: 8 tests (invalid selector rejection)
- `NonJSIndexTrimmingTests`: 4 tests (trimming grammar)

### Scope

This is NOT a complete CSS parser. Only the 4 selector forms above are supported.
