# 非 JS 真实书源端到端测试样本

## 书源信息
- 名称：得奇小说（优+++）
- 地址：https://www.deqibook.com
- 类型：非 JS 书源
- 登录：不需要

## 目录结构
- `booksource.json` - 书源配置文件
- `search_input.json` - 搜索输入参数
- `fixtures/` - HTML 测试样本
  - `search.html` - 搜索结果页面
  - `detail.html` - 书籍详情页面
  - `toc.html` - 目录页面
  - `content.html` - 章节内容页面
- `expected/` - 预期输出
  - `search_result.json` - 搜索结果预期
  - `detail_result.json` - 详情结果预期
  - `toc_result.json` - 目录结果预期
  - `content_result.json` - 内容结果预期
- `metadata.yml` - 样本元数据

## 测试命令
```bash
# 运行端到端测试
cd Core && swift test --filter RealWorldNonJSE2ECase001Tests

# 验证 JSON/YAML 文件
python3 -c "import json, pathlib; for p in pathlib.Path('samples/e2e').rglob('*.json'): json.load(open(p, encoding='utf-8')); print('JSON OK', p)"
ruby -e 'require "yaml"; Dir["samples/e2e/**/*.yml"].each { |f| YAML.load_file(f); puts "YAML OK #{f}" }'
```