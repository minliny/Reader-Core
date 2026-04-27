# Parser V3 Capability Reclassification

Date: 2026-04-27

## Decision

`CASE_023 = INVALID_DUE_TO_SCOPE_DRIFT`.

The changes introduced by `5173ece` and `e8437ea` are retained, but they are not evidence for a second real-world pass case. They are reclassified as Parser V3 capability work and must be audited, tested, and documented independently from any future real-world case.

Current real-world status remains:

```text
FIRST_REAL_PASS_CASE_ESTABLISHED
real_valid_pass_cases = 1
CASE_023 = INVALID_DUE_TO_SCOPE_DRIFT
NOT baseline ready
```

## Why Case 023 Is Invalid

The case_023 attempt did not land as an independent real-world case with its own stable sample directory, metadata, expected outputs, matrix entry, failure reason, and regression result. The same change range also modified Parser runtime behavior and public API surface. That mixes candidate evaluation with capability implementation, so the result cannot be counted as a real-world pass case.

Future case_023 work must evaluate an already-existing Parser capability boundary. It must not modify Parser source, selector semantics, parser protocols, parser public API, or shared freeze gates in the same attempt.

## Why 5173ece / e8437ea Are Not Case 023 Evidence

The `5865c64..HEAD` audit shows Parser source changes in:

- `Core/Sources/ReaderCoreParser/NonJSParserEngine.swift`
- `Core/Sources/ReaderCoreParser/NonJSRuleScheduler.swift`
- `Core/Sources/ReaderCoreParser/GroupConsistencySingleKeyConstraint.swift`
- `Core/Sources/ReaderCoreParser/GroupConsistencyPairExactConstraint.swift`

The same range adds or updates targeted Parser tests for selector attributes, descendant selectors, text filters, public API, group consistency, and real-world regression gates. Because these changes expand Parser behavior, they are capability work. They are clean-room Parser extensions in this repository; no external GPL implementation code is copied, translated, or adapted.

## Capability Blocks

### V3_ATTRIBUTE_EXTRACTION_MINIMAL

- status: `implemented_and_tested`
- scope:
  - `selector@href`
  - `selector@src`
  - `selector@content`
  - strict `selector@attr` semantics: attributes are read from the selected node only
- evidence:
  - tests: `Core/Tests/ReaderCoreParserTests/AttributeExtractionMinimalTests.swift`
  - matrix: `samples/matrix/parser_capability_matrix.yml` -> `v3_attribute_extraction_minimal`
- unsupported:
  - attribute selector syntax such as `a[href]`
  - pseudo selectors such as `:eq(0)`
  - child selector syntax with `>`
  - unsupported attributes such as `onclick`
  - regex selector semantics
- risk:
  - uses regex-based HTML extraction in `NonJSRuleScheduler`; acceptable only for this minimal bounded slice
  - V2 baseline risk is controlled by compatibility assertions in the targeted tests
  - case_022 freeze gate risk is controlled by `Case022FirstRealPassFreezeGateTests` and `Case022FirstRealPassTests`

### V3_DESCENDANT_SELECTOR_MINIMAL

- status: `implemented_and_tested`
- scope:
  - one-level `parent child`
  - `parent child@href`
  - `parent child@src`
  - `parent child@content`
  - `parent child@text`
  - `parent child@html`
- evidence:
  - tests: `Core/Tests/ReaderCoreParserTests/DescendantSelectorMinimalTests.swift`
  - matrix: `samples/matrix/parser_capability_matrix.yml` -> `v3_descendant_selector_minimal`
- unsupported:
  - multi-level descendant selectors
  - `>` child selectors
  - attribute selector syntax
  - pseudo selectors
  - index selectors
  - JS rules
  - regex selector semantics
- risk:
  - uses regex-based parent/child HTML extraction in `NonJSRuleScheduler`
  - may affect V2-adjacent selector dispatch, so V2 simple selector compatibility tests remain required
  - case_022 freeze gate must stay green before any real-world status change

### V3_TEXT_FILTER_MINIMAL

- status: `implemented_and_tested`
- scope:
  - `text.xxx`
  - `text.xxx@attr`
  - `parent text.xxx`
  - `parent text.xxx@attr`
  - minimal clickable ancestor semantics for nested text inside a clickable node
- evidence:
  - tests: `Core/Tests/ReaderCoreParserTests/TextFilterMinimalTests.swift`
  - matrix: `samples/matrix/parser_capability_matrix.yml` -> `v3_text_filter_minimal`
- unsupported:
  - regex text filters
  - pseudo selectors
  - multi-text conditions
  - index selectors
  - JS rules
  - sibling fallback
  - arbitrary ancestor fallback
- risk:
  - uses regex-based tag scanning in `NonJSRuleScheduler`
  - minimal clickable ancestor behavior is intentionally narrow and must not be generalized without new samples/tests/matrix updates
  - case_022 freeze gate must remain independent of this capability block

### BOOK_INFO_PUBLIC_API

- status: `implemented_and_tested`
- scope:
  - `NonJSParserEngine` conforms to `BookInfoParser`
  - `parseBookInfoResponse(_:source:detailURL:)`
  - `.bookInfo` scheduler flow integration through `ruleBookInfo`
- evidence:
  - tests: `Core/Tests/ReaderCoreParserTests/ParserPublicAPITests.swift`
  - real-world usage guard: `Core/Tests/ReaderCoreParserTests/Case022FirstRealPassTests.swift`
  - matrix: `samples/matrix/parser_capability_matrix.yml` -> `book_info_public_api`
- unsupported:
  - no new Reader-iOS coupling
  - no Reader-iOS reverse dependency
  - no guarantee that a real-world case is valid solely because the public API exists
- risk:
  - line-oriented `bookName|author|coverURL|intro|tocURL` parsing remains a minimal contract
  - malformed or empty book info still fails with Parser flow errors
  - does not establish a new real-world pass case

### GROUP_CONSISTENCY_RUNTIME

- status: `implemented_and_tested`
- scope:
  - `GroupConsistencySingleKeyConstraint`
  - `GroupConsistencyPairExactConstraint`
  - existing triplet slice remains separately documented
- evidence:
  - tests:
    - `Core/Tests/ReaderCoreParserTests/GroupConsistencySingleKeyFixtureTests.swift`
    - `Core/Tests/ReaderCoreParserTests/GroupConsistencySingleKeySnapshotTests.swift`
    - `Core/Tests/ReaderCoreParserTests/GroupConsistencyPairExactFixtureTests.swift`
    - `Core/Tests/ReaderCoreParserTests/GroupConsistencyPairExactSnapshotTests.swift`
  - matrix:
    - `samples/matrix/parser_capability_matrix.yml` -> `v3_first_slice`
    - `samples/matrix/parser_capability_matrix.yml` -> `v3_second_slice`
- classification:
  - belongs to Parser V3 capability work
  - does not belong to case_023
  - already has fixture/snapshot tests
  - should remain separately documented from real-world pass cases
- unsupported:
  - topology inference
  - dynamic key count
  - fuzzy matching or alternate comparison strategies
  - persistence or facade expansion
- risk:
  - does not parse HTML and does not add regex HTML risk
  - does not change V2 selector baseline directly
  - must not be counted as real-world parser pass evidence

## Reclassification Boundary

Parser extensions from `5173ece` / `e8437ea` may remain in history and in the codebase. The semantic correction is documentation and matrix classification:

- they are Parser V3 capability blocks
- they are not a case_023 result
- they do not increase `real_valid_pass_cases`
- they do not establish a regression baseline

Next case_023 must be restarted as a clean real-world evaluation under the existing Parser capability boundary, without Parser source changes in the same work item.

## Verification on 2026-04-27

Targeted validation passed after temporarily moving untracked duplicate `* 2.swift` files out of the test target and restoring them afterward:

- `swift test --filter AttributeExtractionMinimalTests`: PASS
- `swift test --filter DescendantSelectorMinimalTests`: PASS
- `swift test --filter TextFilterMinimalTests`: PASS
- `swift test --filter ParserPublicAPITests`: PASS
- `swift test --filter Case022FirstRealPassFreezeGateTests`: PASS
- `swift test --filter Case022FirstRealPassTests`: PASS
- `swift test --filter GroupConsistency`: PASS

Full parser-suite validation was attempted:

- `swift test --filter ReaderCoreParserTests`: FAIL
- failure area: existing real-world regression tests, not the V3 capability blocks above
- observed failures include missing `metadata.yml`, missing `regression_matrix.yml` / `regression_report.md` from the test's computed fixture root, and `RealWorldNonJSE2ERegressionTests.testCase001FullPipeline` aborting on missing `samples/real_world/non_js/case_001/fixtures/search.html`

Data-file validation:

- JSON parse check for `samples/parser`, `samples/real_world/non_js`, and `samples/booksources/raw_online_dump`: PASS
- YAML parse check for `samples/**/*.yml`: FAIL on existing `samples/reports/auto/auto_908460e4_probe.yml` control character at line 1 column 1
- `samples/matrix/parser_capability_matrix.yml`: PASS
