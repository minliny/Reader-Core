# Text Filter Minimal

测试 V3_TEXT_FILTER_MINIMAL 能力的最小文本过滤功能。

## 语义定义

`text.xxx@attr` 规则的语义：

1. **命中文本节点自身**：首先从命中文本所在的节点自身提取属性
2. **最小可点击祖先节点**：如果命中文本节点没有所需属性，允许从直接包裹的父标签（最小可点击祖先）提取属性
3. **禁止 fallback**：禁止以下行为：
   - 查找兄弟节点
   - 查找后代节点
   - 查找任意更高层祖先
   - 任何其他 fallback 行为

## 配置

- **minimal_clickable_ancestor_allowed**: true
- **sibling_fallback**: false
- **descendant_fallback**: false
- **arbitrary_ancestor_fallback**: false

## 测试用例

| 测试用例 | 描述 | 选择器 | 期望结果 |
|---------|------|-------|----------|
| simple_text_href | 从简单文本提取 href | `text.目录@href` | 提取 href 属性 |
| chinese_text_href | 从中文文本提取 href | `text.全集目录@href` | 提取 href 属性 |
| parent_scoped_text | 从父容器内的文本提取 href | `.nav text.下一章@href` | 在 .nav 范围内提取 href |
| sibling_tag_text_filter | 兄弟标签测试 | `text.目录@href` | 空数组（禁止找兄弟） |
| minimal_clickable_ancestor_text_filter | 最小可点击祖先测试 | `text.目录@href` | 从父标签提取 href |

## 运行测试

```bash
cd Core && swift test --disable-sandbox --filter TextFilterMinimalTests
```

## 验证

- JSON 格式校验
- YAML 格式校验
- 测试覆盖所有语义规则
