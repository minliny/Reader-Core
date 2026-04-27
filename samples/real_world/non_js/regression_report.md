# Non JS Real World Regression Report

## 0. Status Digest (machine-checked by Case022FirstRealPassFreezeGateTests)

```
marker = FIRST_REAL_PASS_CASE_ESTABLISHED
case_022 = PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES
real_valid_pass_cases = 1
```

This digest is the canonical short-form status. Any text in the rest of the file
that conflicts with it is wrong and must be reconciled to it. The freeze gate
asserts that this file does **not** contain a "regression baseline ready" claim
(the forbidden literal token is omitted on purpose so the gate can detect any
accidental upgrade by a future writer).

## 1. Summary

| Metric | Value |
|--------|-------|
| total_cases | 22 |
| passed_cases | 11 |
| partial_cases | 1 |
| failed_cases | 0 |
| blocked_cases | 0 |
| invalid_cases | 10 |
| pass_rate | 54.5% |

## 2. Case Classification

| Category | Count | Cases | Notes |
|----------|-------|-------|-------|
| real_valid_cases | 1 | case_022 | sudugu.org - real fetch, V2+V3 rules, FIRST_REAL_PASS_CASE_ESTABLISHED |
| real_partial_cases | 1 | case_021 | snapd.net - detail OK, toc/content blocked |
| real_blocked_cases | 0 | - | - |
| sample_cases | 10 | case_001 - case_010 | Sample data, not real-world HTML |
| synthetic_cases | 10 | case_011 - case_020 | Generated data, marked invalid |

## 3. Valid Cases Only (Real-World HTML)

| Metric | Value |
|--------|-------|
| total_real_valid_cases | 1 |
| real_valid_pass_cases | 1 |
| pass_rate_real | 100% (1/1) — single-case sample, NOT a baseline |

**Note**: case_022 已通过真实抓取 + 真实 Parser 端到端验证（detail/toc/content 三段全部 PASS）。
当前仅满足 `FIRST_REAL_PASS_CASE_ESTABLISHED`，**不等于** "regression baseline ready" 状态（该升级标识被 freeze gate 显式禁止出现于本文件）。

## 4. CASE_022_FIRST_REAL_PASS_CASE_ESTABLISHED

### Site

| Site | Result | Reason |
|------|--------|--------|
| sudugu.org | ✅ PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES | Static HTML, no JS, V2+V3 rules sufficient |

### Details
- **Site**: sudugu.org
- **Case**: case_022
- **Pipeline**: detail → toc → content（真实执行通过）
- **HTML Source**: 真实抓取（curl，HTTP 200，原样字节，未清洗）
- **Rules**: V2+V3 边界内 — `css:h1` / `css:#list a@href` / `css:.con`
- **Test**: `swift test --filter Case022FirstRealPassTests`
- **Evidence**:
  - detail PASS — tocUrl 可提取
  - toc PASS — 659 chapters
  - content PASS — 3465 chars
- **Known issues (本轮不修)**:
  - detail.bookName 含字数前缀
  - detail.author 为空
  - toc.chapterTitle == chapterURL（单规则无法输出 title|url 配对）

## 5. Stage Pass Rate (Valid Cases Only)

Source: case_022（real_valid_cases = 1）。样本量极小，仅作里程碑指示，非统计基线。

| Stage | Pass Rate |
|-------|-----------|
| search | n/a（本轮不评 search） |
| detail | 100% (1/1) — tocUrl 提取 |
| toc | 100% (1/1) — 659 chapters |
| content | 100% (1/1) — 3465 chars |

## 6. Failure Pattern

| Failure Type | Count | Cases |
|-------------|-------|-------|
| selector_miss | 0 | - |
| selector_unsupported | 0 | - |
| rule_format_unsupported | 0 | - |
| pipeline_gap | 0 | - |
| network_fixture_unavailable | 0 | - |
| expected_mismatch | 0 | - |
| content_extraction_error | 0 | - |
| metadata_incomplete | 0 | - |
| js_required | 0 | - |
| login_required | 0 | - |
| synthetic_fixture | 10 | case_011 - case_020 |
| missing_real_html | 10 | case_001 - case_010 (sample, not real) |
| anti_scraping_response | 1 | case_021 (toc/content blocked) |
| no_accessible_real_non_js_source_html | 0 | (resolved by case_022 real pass) |
| detail_field_partial_extraction | 1 | case_022 (bookName 字数前缀；author 空；toc title==url) — known issues, 不阻断 phase 判定 |

## 7. Parser Feature Coverage

| Feature | Usage | Cases |
|---------|-------|-------|
| simple_selector_class | ✓ | case_001 - case_021 |
| simple_selector_id | ✓ | case_002 |
| simple_selector_tag | ✓ | case_003 |
| simple_selector_tag_class | ✓ | case_003 |
| child_selector | ✓ | case_002 |
| og_meta_tags | ✓ | case_021 |
| css_selector | ✓ | case_022 (partial) |
| html_extraction | ✓ | case_022 (partial) |
| trimming_suffix | - | - |
| group_consistency_single_key | - | - |
| group_consistency_pair_exact | - | - |
| group_consistency_triplet_exact | - | - |

## 8. Current Capability Boundary

### 支持的能力
- 简单的 CSS 选择器（class、ID、tag、child 选择器）
- 搜索结果解析（支持 title、detailURL、author 字段）
- 详情页解析（支持 bookName、author、coverURL、intro、tocURL 字段）
- 目录解析（支持 chapterTitle、chapterURL 字段）
- 内容解析（支持正文提取）

### 不支持的能力
- 复杂的 CSS 选择器（如属性选择器、伪类选择器等）
- 规则格式中的 `@` 语法
- 动态渲染（JS 依赖）
- 登录验证
- 动态签名/加密接口

### 暂不处理的能力
- 网络请求（使用本地 fixture）
- 复杂的规则格式
- 多页内容加载

## 9. Baseline Decision

### 当前状态（精确）
```
FIRST_REAL_PASS_CASE = YES
case_022 = PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES
marker = FIRST_REAL_PASS_CASE_ESTABLISHED
```

### 不能宣称
- "regression baseline ready" 类升级标识（freeze gate 禁止其字面字符串出现于本文件）
- "regression expanded" 类升级标识（同上）

样本量与 pipeline 完整度都不足以支持任何此类升级。

### 判定理由
1. **里程碑达成**：case_022 (sudugu.org) 完成真实抓取 + 真实 Parser 端到端验证（detail/toc/content 三段全部 PASS）
2. **样本不足**：real_valid_cases = 1，远低于 EXPANDED 所需的 ≥5 个真实 case 且 ≥3 个完整 pipeline
3. **case_021** 仍为 partial case（detail OK, toc/content blocked by anti-scraping）
4. **case_001 ~ case_010** 为 sample 数据，不等同于真实 HTML
5. **case_011 ~ case_020** 为 generated 数据，已标记为 invalid

### CASE_022_FIRST_REAL_PASS_CASE_ESTABLISHED
- **案例**: case_022 (sudugu.org)
- **状态**: PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES
- **真实证据**: `swift test --filter Case022FirstRealPassTests` PASS（详见 `case_022/first_real_pass_report.txt`）
- **遗留瑕疵**（本轮不修）:
  - bookName 含字数前缀
  - author 字段未提取
  - toc chapterTitle == chapterURL（单规则配对受限）

### Baseline 扩展条件（仍然待满足）
要从当前里程碑升级到正式的 regression baseline 状态（其升级标识被 freeze gate 禁止出现于本文件），需要：
1. 至少 5 个真实书源 case（当前 1）
2. 每个 case 必须有真实 HTML（search, detail, toc, content）
3. 每个 case 必须使用真实 booksource 规则
4. 完整 pipeline 验证（detail → toc → content）
5. 所有 fixtures 必须标记为 fixture_origin: real

### 下一步（**本轮不执行**）
- 继续收集：更多可访问的非 JS 书源
- 扩展测试：增加更多真实书源 case
- 保持验证：定期更新 regression 测试
- 不生成 HTML，不把 sample/generated 数据标记为 real
- 不修改 parser，不伪造测试通过