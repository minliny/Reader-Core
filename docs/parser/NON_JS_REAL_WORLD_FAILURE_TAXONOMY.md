# Non JS Real World Failure Taxonomy

## 1. selector_miss

### Definition
规则选择器当前不匹配真实 HTML。

### Detection Rule
- 选择器执行后返回空结果
- 选择器执行后返回与预期不符的结果

### Allowed Action
- 检查 HTML 结构是否正确
- 检查选择器语法是否正确
- 确保选择器能够匹配目标元素

### Prohibited Action
- 不要修改 HTML 结构来适应选择器
- 不要简化选择器以通过测试

### Example
- 选择器 `css:.item` 无法匹配 HTML 中的元素
- 选择器 `css:#list` 无法找到对应的元素

## 2. selector_unsupported

### Definition
真实规则使用当前 Parser 不支持的 selector。

### Detection Rule
- 选择器包含 Parser 不支持的语法
- 选择器使用复杂的 CSS 选择器功能

### Allowed Action
- 记录为 known gap
- 等待 Parser 能力扩展

### Prohibited Action
- 不要修改规则以使用不支持的选择器
- 不要为了通过测试而简化规则

### Example
- 选择器使用属性选择器 `[attr=value]`
- 选择器使用 `@` 语法提取属性

## 3. rule_format_unsupported

### Definition
书源规则格式当前无法解析。

### Detection Rule
- 规则格式不符合 Parser 预期
- 规则包含 Parser 无法处理的语法

### Allowed Action
- 记录为 known gap
- 等待 Parser 能力扩展

### Prohibited Action
- 不要修改规则格式以适应 Parser
- 不要为了通过测试而简化规则

### Example
- 规则使用复杂的 JSON 结构
- 规则使用 Parser 不支持的特殊语法

## 4. pipeline_gap

### Definition
search/detail/toc/content 数据传递断点。

### Detection Rule
- 数据无法从一个阶段传递到下一个阶段
- 某个阶段的输出格式与下一个阶段的输入格式不匹配

### Allowed Action
- 检查数据传递逻辑
- 确保每个阶段的输出格式正确

### Prohibited Action
- 不要跳过失败的阶段
- 不要使用硬编码数据

### Example
- search 结果中的 URL 格式与 detail 阶段的预期不匹配
- toc 结果中的章节 URL 格式与 content 阶段的预期不匹配

## 5. network_fixture_unavailable

### Definition
无法获取真实 HTML fixture。

### Detection Rule
- 无法访问目标网站
- 网站返回错误或拒绝访问

### Allowed Action
- 使用已有的 fixture
- 记录为 known gap

### Prohibited Action
- 不要伪造 fixture
- 不要使用不相关的 fixture

### Example
- 网站无法访问
- 网站返回 404 错误

## 6. expected_mismatch

### Definition
actual 与 expected 不一致。

### Detection Rule
- 解析结果与预期输出不匹配
- 解析结果缺少预期的字段

### Allowed Action
- 检查解析逻辑
- 检查 expected 文件是否正确
- 确保 fixture 与规则匹配

### Prohibited Action
- 不要修改 expected 以匹配错误的解析结果
- 不要修改 fixture 以适应解析结果

### Example
- 解析结果缺少 title 字段
- 解析结果的 URL 格式与预期不符

## 7. content_extraction_error

### Definition
正文提取失败或噪声过多。

### Detection Rule
- 内容解析为空或几乎为空
- 内容中包含大量无关的 HTML 标签或噪声

### Allowed Action
- 检查 content 规则是否正确
- 确保选择器能够匹配正文内容

### Prohibited Action
- 不要为了通过测试而简化内容
- 不要修改 fixture 以减少噪声

### Example
- 内容解析为空字符串
- 内容中包含大量 HTML 标签

## 8. metadata_incomplete

### Definition
样本元数据不完整。

### Detection Rule
- metadata.yml 缺少必要字段
- metadata.yml 字段值不正确

### Allowed Action
- 补全 metadata.yml 中的缺失字段
- 修正 metadata.yml 中的错误值

### Prohibited Action
- 不要使用不完整的 metadata
- 不要跳过 metadata 验证

### Example
- metadata.yml 缺少 id 字段
- metadata.yml 中的 covered_stages 不完整

## 9. js_required

### Definition
该书源实际依赖 JS。

### Detection Rule
- 网站使用动态渲染
- 规则包含 JS 执行逻辑

### Allowed Action
- 将书源标记为 js_required
- 记录为 known gap

### Prohibited Action
- 不要尝试使用非 JS 解析器解析 JS 依赖的书源
- 不要为了通过测试而简化规则

### Example
- 规则包含 `@js:` 前缀
- 网站内容通过 JS 动态加载

## 10. login_required

### Definition
该书源实际需要登录。

### Detection Rule
- 网站返回登录页面
- 规则包含登录相关逻辑

### Allowed Action
- 将书源标记为 login_required
- 记录为 known gap

### Prohibited Action
- 不要尝试解析需要登录的书源
- 不要为了通过测试而跳过登录步骤

### Example
- 网站返回 401 错误
- 规则包含登录检查逻辑
