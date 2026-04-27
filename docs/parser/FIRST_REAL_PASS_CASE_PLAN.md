# First Real Pass Case Plan

## Status (2026-04-27)

```
FIRST_REAL_PASS_CASE = YES
case_022 = PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES
marker = FIRST_REAL_PASS_CASE_ESTABLISHED
case_022 completed
```

- **Completed case**: case_022 (sudugu.org) — case_022 completed
- **Invalidated attempt**: case_023 attempt invalidated due to scope drift; Parser extensions from `5173ece` / `e8437ea` are reclassified as Parser V3 capability work, not a real-world pass case.
- **Test**: `swift test --filter Case022FirstRealPassTests` → PASS
- **Real evidence**:
  - detail: tocUrl 可提取
  - toc: 659 chapters
  - content: 3465 chars
  - 真实 HTML（curl，原样字节）+ 真实 Parser + 真实站点
- **Plan phases marked complete**: Site Selection (sudugu.org), HTML Collection (curl 原样落盘), Rule Creation (V2+V3), Pipeline Execution (3/3 stage PASS), Documentation (README/metadata/report)
- **Known issues left in case_022 (本轮不修)**:
  - detail.bookName 含字数前缀
  - detail.author 为空
  - toc.chapterTitle == chapterURL（单规则无法输出 title|url 配对）
- **NOT claimed**:
  - "regression baseline ready" 类升级标识（freeze gate 显式禁止该字面字符串出现于 regression_report.md）
  - "regression expanded" 类升级标识

下一步建议参见本文末尾「Next Steps After Success」与 `samples/real_world/non_js/regression_report.md` §9。

## Case 023 Boundary After Scope Drift

`CASE_023 = INVALID_DUE_TO_SCOPE_DRIFT`.

The case_023 attempt mixed real-world evaluation with Parser source/API expansion, so it cannot count as a second real-world pass case. The current real-world count remains `real_valid_pass_cases = 1`, with case_022 as the only established first real pass case.

Future case_023 work must not modify Parser source, parser protocols, selector semantics, parser public API, case_022 files, or freeze-gate expectations. It must evaluate the already-documented Parser capability boundary and land the required sample, metadata, expected outputs, matrix binding, failure/success reason, and regression result as an independent real-world case.

---

## Objective

Establish a **FIRST_REAL_PASS_CASE** for the non-JS parser by successfully parsing a real-world book source from detail page to content page using only current V3 capabilities.

## Why This Matters

- **Validation**: Prove that the current V3 parser capabilities can handle a real-world scenario
- **Foundation**: Create a baseline for future real-world regression testing
- **Confidence**: Build confidence in the parser's ability to handle real sources
- **Direction**: Provide clear direction for future capability expansion

## Plan Overview

### Phase 1: Site Selection

1. **Criteria for Selection**
   - Simple site structure with minimal JavaScript
   - Static HTML content (no AJAX-loaded content)
   - Clear, consistent selectors
   - No anti-scraping measures
   - Accessible without authentication

2. **Recommended Approach**
   - Select a small, independent book site
   - Avoid large commercial sites (they often have complex anti-scraping)
   - Look for sites with clean HTML structure
   - Test basic access before committing

### Phase 2: HTML Collection

1. **Required Files**
   - `detail.html`: Book detail page with title, author, and TOC link
   - `toc.html`: Table of contents page with chapter links
   - `content.html`: Sample chapter content page

2. **Collection Method**
   - Manually save HTML from browser (right-click → Save Page As)
   - Ensure complete HTML (including all necessary elements)
   - Save as clean HTML (not MHTML)
   - Store first-pass evidence in `samples/real_world/case_022/`
   - Future `case_023` evidence must be created only after the Parser capability boundary is fixed for that attempt

### Phase 3: Rule Creation

1. **Rule Requirements**
   - Use only current V3 capabilities
   - Minimal, focused selectors
   - Clear, readable format
   - Well-documented

2. **Required Rules**
   - `ruleBookInfo`: Extract book metadata and TOC URL
   - `ruleToc`: Extract chapter list and URLs
   - `ruleContent`: Extract chapter content

3. **Rule Testing**
   - Test each rule individually
   - Verify extraction works with saved HTML
   - Ensure no JavaScript dependencies

### Phase 4: Pipeline Execution

1. **Execution Steps**
   - Load detail.html and extract book info + TOC URL
   - Load toc.html and extract chapter list
   - Load content.html and extract chapter content
   - Verify end-to-end flow works

2. **Success Criteria**
   - All rules execute without errors
   - All required data is extracted correctly
   - No JavaScript is needed
   - Pipeline completes successfully

### Phase 5: Documentation

1. **Required Documentation**
   - Case directory with HTML files
   - Rule files
   - README.md with case description
   - Test results

2. **Regression Integration**
   - Only after successful execution
   - Update regression_matrix.yml
   - Add to regression test suite

## Common Pitfalls to Avoid

1. **Choosing the Wrong Site**
   - Site with heavy JavaScript
   - Site with anti-scraping measures
   - Site with inconsistent structure

2. **Overcomplicating Rules**
   - Using complex selectors
   - Relying on JavaScript
   - Creating brittle rules

3. **Incomplete HTML**
   - Missing critical elements
   - Saving only partial HTML
   - Not capturing the full page structure

4. **Skipping Validation**
   - Not testing individual rules
   - Not verifying end-to-end flow
   - Not documenting results

## Success Metrics

- **FIRST_REAL_PASS_CASE**: Established and documented
- **End-to-End Pipeline**: Works from detail to content
- **No JavaScript**: All parsing done with non-JS capabilities
- **Clear Documentation**: Complete case documentation
- **Regression Inclusion Candidate**: eligible for regression suite review without implying broader baseline readiness

## Next Steps After Success

1. **Update Parser Status**: Mark FIRST_REAL_PASS_CASE as achieved
2. **Expand Coverage**: Identify next site to evaluate only after freezing the Parser capability boundary for that attempt
3. **Capability Analysis**: Use success to inform future capability expansion
4. **Build Confidence**: Provide confidence for future integration

## Conclusion

Building the FIRST_REAL_PASS_CASE is a critical milestone for the non-JS parser. By following this plan and focusing on a simple, achievable goal, we can establish a solid foundation for future real-world parsing capabilities.
