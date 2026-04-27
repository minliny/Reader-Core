# case_022: 速读谷

## 状态

```
FIRST_REAL_PASS_CASE = YES
case_022 = PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES
marker = FIRST_REAL_PASS_CASE_ESTABLISHED
```

仅证明：真实站点 + 真实 HTML + 真实 Parser 端到端可跑通。
**不**证明 `NON_JS_REAL_WORLD_REGRESSION_BASELINE_READY`。

## 书源信息
- **名称**: 速读谷
- **URL**: https://www.sudugu.org/
- **类型**: 静态 HTML，无 JS 依赖

## fixtures（真实抓取，未清洗）
- `fixtures/detail.html` ← `https://www.sudugu.org/51/`
- `fixtures/toc.html`    ← `https://www.sudugu.org/51/`（与 detail 同页，#dir 锚点）
- `fixtures/content.html` ← `https://www.sudugu.org/51/3612068.html`
- 抓取方式：`curl --max-time 25`，HTTP 200，原样字节落盘

## V2+V3 规则（booksource.json）
- `ruleBookInfo: css:h1`             — V2 标签选择器
- `ruleToc: css:#list a@href`        — V3 一层后代 + 属性提取
- `ruleContent: css:.con`            — V2 类选择器

## 真实执行结果

| 阶段 | 状态 | 关键证据 |
|------|------|----------|
| detail  | PASS | tocUrl 可提取（fallback 至 detailURL） |
| toc     | PASS | 659 chapters |
| content | PASS | 3465 chars |

执行：

```
swift test --filter Case022FirstRealPassTests
```

详细输出见 `first_real_pass_report.txt`。

## 已知遗留（本轮不修）

- detail.bookName 含「563.2万字」前缀（`<h1>` 内嵌 `<i>字数</i>`）
- detail.author 为空（作者信息位于 `<h1>` 之外的 `<p>` 中，单规则无法在 V2/V3 边界内取到）
- toc.chapterTitle 等于 chapterURL（单条 ruleToc 无法输出 `title|url` 配对，受当前 NonJSParserEngine 行 splitting 形态约束）

按本轮指令：**不修 parser，不雕刻字段**。这些瑕疵留待后续阶段处理。

## 测试目标
验证非 JS 解析器能否成功解析速读谷的小说页面，包括：
- 小说详情页 (detail.html)
- 章节列表页 (toc.html)
- 章节内容页 (content.html)

## 测试文件
- `fixtures/detail.html`: 小说详情页
- `fixtures/toc.html`: 章节列表页
- `fixtures/content.html`: 章节内容页
- `expected/detail_result.json`: 历史快照（语义级，非 phase 判定门）
- `expected/toc_result.json`: 历史快照
- `expected/content_result.json`: 历史快照
- `booksource.json`: V2+V3 规则
- `metadata.yml`: 测试元数据 + 验证记录
- `first_real_pass_report.txt`: 真实执行报告

## 测试流程
1. 解析 detail.html 获取基本信息和目录 URL
2. 解析 toc.html 获取章节列表
3. 解析 content.html 获取章节内容
4. 验证 detail/toc/content 三段非空（非严格快照对比）

## 注意事项
- 该网站使用静态 HTML 结构，无 JS 依赖
- 章节列表通过 `#dir` 锚点访问，但实际内容已包含在详情页中
- 内容页使用简单的 CSS 选择器即可提取
