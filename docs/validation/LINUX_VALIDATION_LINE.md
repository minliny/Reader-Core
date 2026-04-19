# Linux Validation Line

## 两条验证线的定位

| 验证线 | 用途 | 运行平台 | 目标 |
|--------|------|----------|------|
| **Core Capability Line** | 验证 NonJS 解析核心能力（Search / TOC / Content） | Linux WSL2 / macOS | 快速反馈 |
| **Full-Suite Line** | 完整 XCTest 测试 + 所有 runner | macOS | 全面验证 |

---

## A. Core Capability Line

### 本地 WSL2 执行

```bash
# 1. 进入 WSL（假设 Swift 已安装在 ~/swift）
wsl -d Ubuntu-24.04 -- bash -c "
  export PATH=~/swift/usr/bin:/usr/bin:/bin:\$PATH
  cd /mnt/c/Users/Administrator/Documents/Reader-Core

  # 2. 构建核心库
  swift build --package-path Core --configuration release --target ReaderCoreParser

  # 3. 运行 LinuxSmokeRunner（推荐）
  swift run --package-path Core --configuration release LinuxSmokeRunner
"
```

**或**直接用预编译产物：

```bash
swift run --package-path Core --configuration release LinuxSmokeRunner
```

### CI（macOS）
现有 `sample001-nonjs-smoke.yml` 已在 macOS-14 上验证 NonJS runners（Sample001–005）。

### 验证内容
- Search 解析（fixture HTML → `SearchResultItem[]`）
- TOC 解析（fixture HTML → `TOCItem[]`）
- Content 解析（fixture HTML → `ReadingFlowPage.content`）

### 已知状态
| 模块 | Linux 构建 | macOS 构建 |
|------|-----------|-----------|
| ReaderCoreFoundation | ✅ | ✅ |
| ReaderCoreModels | ✅ | ✅ |
| ReaderCoreProtocols | ✅ | ✅ |
| ReaderCoreParser | ✅ | ✅ |
| ReaderCoreCache | ✅ | ✅ |
| ReaderPlatformAdapters | ✅（需 URLSession shim） | ✅ |
| ReaderCoreJSRenderer | ❌（JavaScriptCore） | ✅ |
| ReaderCoreNetwork | ⚠️（部分 API） | ✅ |
| LinuxSmokeRunner | ✅ | ✅ |

---

## B. Full-Suite Line

### CI（macOS）
`core-swift-tests.yml` 在 macOS-14 上运行完整 `swift test`。

### 本地 macOS
```bash
cd Core
swift test --verbose
```

### Linux 阻塞清单

`swift test` 在 Linux 上被以下问题阻塞，**无需修**，属于平台差异：

| 阻塞点 | 原因 | 状态 |
|--------|------|------|
| `AutoSampleExtractorRunner` | `import CryptoKit`（Apple-only） | 已知 |
| `ReaderCoreNetworkTests/LoginBootstrapTests.swift` | `URLProtocol` 在 Linux 上需 `import FoundationNetworking`，测试代码未导入 | 已知 |
| `ReaderCoreJSRendererTests` | `import JavaScriptCore`（Apple-only） | 已知 |
| `@Sendable` 警告 | Swift 6 严格并发要求，当前 Swift 5.9 为 warning | 已知 |

**Full-Suite 在 Linux 上不要求通过**，只在 macOS 上运行即可。

---

## 执行顺序建议

```
1. 先跑 Core Capability Line（快，< 30s）
   → 如果失败：Parser 代码问题，立即可见
   → 如果通过：核心解析链路正常

2. 再跑 Full-Suite（慢，~5min，macOS only）
   → 只在 macOS 上执行
   → Linux 阻塞不需要修
```

---

## 文件索引

- Core Capability 入口：`Core/LinuxSmokeRunner/`（Linux 独立 runner）
- Core Capability macOS：`Core/Sources/Sample001NonJSSmokeRunner/`（macOS runner）
- Full-Suite macOS CI：`.github/workflows/core-swift-tests.yml`
- NonJS Smoke macOS CI：`.github/workflows/sample001-nonjs-smoke.yml`
- URLSession Linux 兼容修复：`Core/Sources/ReaderPlatformAdapters/URLSessionHTTPClient.swift`
