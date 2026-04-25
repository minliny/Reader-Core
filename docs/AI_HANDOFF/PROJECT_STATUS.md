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

---

## Parser V2 Stable Baseline (merged 2026-04-23)

NonJSRuleScheduler simple selector grammar is unified with a formal AST and strict invalid-selector rejection.

### Build & Test Status

- Post-merge check: `swift test` 331/331 pass on macOS arm64, Swift 6.3.1.

The following selector forms are supported, verified by real-world sample cases and
passing unit tests. This list is the authoritative V2 stable subset.

| Selector form | Example | Sample case | Test |
|---|---|---|---|
| `.class` | `.article-title` | `case_001` | `testCase001_dotClass_multipleHits` |
| `#id` | `#chapter-content` | `case_002` | `testCase002_hashId_singleHit` |
| `tag` | `p` | `case_003` | `testCase003_tag_threeHits` |
| `tag.class` | `li.searchresult` | `case_004` | `testCase004_tagDotClass_filtersNonMatchingTag` |
| `.class` (multi-class boundary) | `.book-item` | `case_005` | `testCase005_boundary_multiClassElement_matchesWhenTargetClassPresent` |

Capability matrix: `samples/matrix/parser_capability_matrix.yml`

### Explicitly Unsupported In V2

- `tag#id`
- `.a.b` / `tag.class.other`
- descendant selector (space)
- attribute selector `[attr]`
- pseudo selector `:`
- combinator `>`
- selector group `,`

Invalid selector forms must return no matches; they must not silently fall back to a broader selector.

### Trimming Grammar

`!` suffix is independent grammar. Illegal suffixes (empty, negative index, invalid chars, leading/trailing/consecutive colons) do NOT activate trimming.

### Test Coverage

- `NonJSTagClassRegressionTests`: selector behavior and tag/class regression coverage
- `SimpleSelectorGrammarTests`: invalid selector rejection
- `NonJSIndexTrimmingTests`: trimming grammar
- `RealWorldParserCasesTests`: reads `case_001` through `case_005` sample files
- `RealWorldParserCasesExtendedTests`: reads `case_006` through `case_020` sample files
- `ParserNegativeBoundaryTests`: reads `negative_case_001` through `negative_case_006` sample files
- `ParserPublicAPITests`: external SwiftPM-style public API access without `@testable`

### Real-World Sample Coverage Line

- 20 positive sample cases: `samples/real_world/parser_cases/case_001` – `case_020`
- 6 negative sample cases: `samples/real_world/parser_negative_cases/negative_case_001` – `negative_case_006`
- Each case: `input.html` + `selector.txt` + `expected.json`
- Clean-room maintained: no external GPL implementation code copied

### Public API Integration Verification

- Verified via `ParserPublicAPITests` — imports `ReaderCoreParser` and `ReaderCoreModels`
  without `@testable`; simulates external iOS SPM consumer call style.
- Entry point: `NonJSParserEngine().parseSearchResponse(_:source:query:)`
- Result: `results.count == 1`, `results[0].title == "A"` for `li.searchresult` on
  `<li class="searchresult">A</li>`

### V3 Preparation Status

V2 remains the stable runtime baseline. V3 planning exists in `docs/parser/PARSER_V3_CAPABILITY_MODEL.md`
and must extend V2 without rewriting or removing the verified V2 subset.

V3 implementation work must be evidence-bound:
- A concrete rule/sample must show a selector or adapter gap outside the V2 subset.
- The gap must be represented by sample data, tests, and matrix/status updates.
- New support must not change the A/B/C/D compatibility-level definitions or failure taxonomy without matching config updates.

### V3 First Slice Status (group_consistency_single_key_constraint)

- Scope: single rule type `single_key_unique` on one key only (`group_consistency_single_key_constraint`).
- Fixture/expected/metadata/matrix bindings:
  - `samples/fixtures/group_consistency/gc_single_key_*.json`
  - `samples/expected/group_consistency/gc_single_key_*.json`
  - `samples/metadata/p0_non_js/group_consistency_single_key/gc_single_key_*.yml`
  - `samples/matrix/compat_matrix.yml` sample entries `gc_single_key_*`
- Tests:
  - `GroupConsistencySingleKeyFixtureTests`
  - `GroupConsistencySingleKeySnapshotTests`
- Runtime:
  - `Core/Sources/ReaderCoreParser/GroupConsistencySingleKeyConstraint.swift`
- Constraints kept:
  - single-key only; no topology/composite-key/facade/persistence expansion
  - stable issue ordering by first occurrence
  - no implicit normalization (no trim/lowercase/auto-correction)
  - clean-room maintained (no external GPL code or Legado Android implementation reference)

### V3 Second Slice Status (group_consistency_multi_key_pair_exact)

- Scope: pair-only rule type `multi_key_pair_unique` with exact tuple uniqueness on exactly two keys.
- Fixture/expected/metadata/matrix bindings:
  - `samples/fixtures/group_consistency_pair/gc_pair_*.json`
  - `samples/expected/group_consistency_pair/gc_pair_*.json`
  - `samples/metadata/p0_non_js/group_consistency_pair/gc_pair_*.yml`
  - `samples/matrix/compat_matrix.yml` sample entries `gc_pair_*`
- Tests:
  - `GroupConsistencyPairExactFixtureTests`
  - `GroupConsistencyPairExactSnapshotTests`
- Runtime:
  - `Core/Sources/ReaderCoreParser/GroupConsistencyPairExactConstraint.swift`
- Constraints kept:
  - only `keys.count == 2`; explicit reject for one-key and three-key rules
  - duplicate key names rejected
  - exact tuple equality only; no trim/lowercase/unicode/type-coercion normalization
  - deterministic issue/evidence ordering by first tuple occurrence
  - reject taxonomy reused as `RULE_INVALID`; no new failure taxonomy
  - no facade/persistence contract changes

### V3 Third Slice Status (group_consistency_multi_key_triplet_exact)

- Scope: triplet-only rule type `multi_key_triplet_unique` with exact tuple uniqueness on exactly three keys.
- Fixture/expected/metadata/matrix bindings:
  - `samples/fixtures/group_consistency_triplet/gc_triplet_*.json`
  - `samples/expected/group_consistency_triplet/gc_triplet_*.json`
  - `samples/expected/group_consistency_triplet/snapshots/gc_triplet_*.snapshot.json`
  - `samples/metadata/p0_non_js/group_consistency_triplet/gc_triplet_*.yml`
  - `samples/matrix/compat_matrix.yml` sample entries `gc_triplet_*`
- Tests:
  - `GroupConsistencyTripletExactFixtureTests`
  - `GroupConsistencyTripletExactSnapshotTests`
- Runtime:
  - `Core/Sources/ReaderCoreParser/GroupConsistencyTripletExactConstraint.swift`
- Constraints kept:
  - only `keys.count == 3`; explicit reject for two-key and four-key rules
  - duplicate key names rejected
  - exact tuple equality only; no trim/lowercase/unicode/type-coercion normalization
  - deterministic issue/evidence ordering by first tuple occurrence
  - reject taxonomy reused as `RULE_INVALID`; no new failure taxonomy
  - no facade/persistence contract changes

---

## Parser Extension Guardrails

These rules apply to all future contributors and agents working on this repo:

1. **Sample first.** Before adding support for any new selector form, a real or clean-room representative sample
   case (`input.html` + `selector.txt` + `expected.json`) must exist in
   `samples/real_world/parser_cases/`.

2. **Three-part update.** Any new supported capability must be accompanied by:
   - A new or updated sample case directory
   - A passing unit test in `RealWorldParserCasesTests.swift` or equivalent
   - An updated entry in `samples/matrix/parser_capability_matrix.yml`

3. **No unverified entries in `supported`.** A selector form must not appear in the
   `supported` list of `parser_capability_matrix.yml` until a passing test confirms it.

4. **V3 is not a replacement for V2.** V3 work must preserve the verified V2 subset and add only evidence-backed capabilities.
