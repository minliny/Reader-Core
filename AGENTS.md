# Reader-Core AI 开发治理总则

## 仓库角色

- 本仓库为 Reader-Core 独立仓。
- 职责：Core 兼容内核、samples、regression、compat、tooling、freeze gate。
- Reader-iOS 依赖本仓 public package/products，不得反向依赖 Reader-iOS。

## 强制规则

1. 兼容格式与行为，不复用实现代码。
2. 禁止复制、翻译、改写 Legado Android 源码。
3. 禁止输出与既有规范冲突的数据结构。
4. 所有兼容性改动都必须绑定样本、失败原因、预期变化、回归结果。
5. 不得跳过 metadata、expected、matrix。
6. 不得修改 A/B/C/D 兼容等级定义。
7. 不得新增 failure taxonomy 而不同时更新配置。
8. 输出优先使用 YAML、JSON、目录树、字段表、模板文件、代码。
9. 不要泛化讨论，不要先讲空计划，直接给可执行结果。
10. 所有实现都必须考虑 clean-room 原则，并说明无外部 GPL 代码搬运。

## 仓库边界

- 本仓库拥有：Core/**、samples/**、tools/**、scripts/(Core)、Core workflows、Core docs
- 本仓库不拥有：iOS App/Shell/Features/Modules、iOS docs/workflows/scripts
- Reader-iOS 只能通过 public package/products 接入 Core

## 公开 Products

- ReaderCoreFoundation
- ReaderCoreModels
- ReaderCoreProtocols
- ReaderCoreParser
- ReaderCoreNetwork
- ReaderPlatformAdapters
- ReaderCoreCache
- ReaderCoreJSRenderer

## 当前状态

- 来源：从 Reader-for-iOS (Reader-iOS) 反向拆分提取（2026-04-14）
- 稳定 tag：0.1.0（根 Package.swift 已就绪）
- Clean-room maintained: yes
- External GPL code copied: no
