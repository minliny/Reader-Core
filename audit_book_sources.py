#!/usr/bin/env python3
import json
import re

# 读取书源数据
def load_book_sources():
    file_path = "samples/booksources/raw_online_dump/all_sources.json"
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

# 检查选择器是否符合 V3 能力要求
def is_valid_selector(selector):
    if not selector:
        return True
    
    # 检查是否包含 JS
    if '@js' in selector or '<js>' in selector or 'java.ajax' in selector:
        return False
    
    # 检查是否包含 XPath
    if selector.startswith('//') or selector.startswith('$'):
        return False
    
    # 检查是否包含复杂选择器
    if ':' in selector and not selector.endswith('@text') and not selector.endswith('@href') and not selector.endswith('@src') and not selector.endswith('@content') and not selector.endswith('@html'):
        return False
    
    # 检查是否包含多层 descendant
    if selector.count(' ') > 1:
        return False
    
    # 检查是否包含正则
    if '##' in selector:
        return False
    
    # 检查是否包含 JSONPath
    if '$.' in selector:
        return False
    
    return True

# 检查规则字段是否符合 V3 能力要求
def audit_source(source):
    source_name = source.get('bookSourceName', 'Unknown')
    bookSourceUrl = source.get('bookSourceUrl', 'Unknown')
    searchUrl = source.get('searchUrl', '')
    ruleSearch = source.get('ruleSearch', {})
    ruleBookInfo = source.get('ruleBookInfo', {})
    ruleToc = source.get('ruleToc', {})
    ruleContent = source.get('ruleContent', {})
    
    # 输出原始规则
    print(f"\n=== {source_name} ===")
    print(f"source_name: {source_name}")
    print(f"bookSourceUrl: {bookSourceUrl}")
    print(f"searchUrl: {searchUrl}")
    print(f"ruleSearch: {json.dumps(ruleSearch, ensure_ascii=False, indent=2)}")
    print(f"ruleBookInfo: {json.dumps(ruleBookInfo, ensure_ascii=False, indent=2)}")
    print(f"ruleToc: {json.dumps(ruleToc, ensure_ascii=False, indent=2)}")
    print(f"ruleContent: {json.dumps(ruleContent, ensure_ascii=False, indent=2)}")
    
    # 审计规则
    issues = []
    
    # 1. ruleContent.content
    content = ruleContent.get('content', '')
    if content and not is_valid_selector(content):
        issues.append("ruleContent.content 不符合 V3 能力要求")
    
    # 2. ruleToc.chapterList
    chapter_list = ruleToc.get('chapterList', '')
    if chapter_list and not is_valid_selector(chapter_list):
        issues.append("ruleToc.chapterList 不符合 V3 能力要求")
    
    # 3. ruleToc.chapterName
    chapter_name = ruleToc.get('chapterName', '')
    if chapter_name and not is_valid_selector(chapter_name):
        issues.append("ruleToc.chapterName 不符合 V3 能力要求")
    
    # 4. ruleToc.chapterUrl
    chapter_url = ruleToc.get('chapterUrl', '')
    if chapter_url and not is_valid_selector(chapter_url):
        issues.append("ruleToc.chapterUrl 不符合 V3 能力要求")
    
    # 5. ruleBookInfo.tocUrl
    if isinstance(ruleBookInfo, dict):
        toc_url = ruleBookInfo.get('tocUrl', '')
        if toc_url and not is_valid_selector(toc_url):
            issues.append("ruleBookInfo.tocUrl 不符合 V3 能力要求")
    
    # 6. 检查是否包含禁止内容
    all_rules = [
        searchUrl,
        json.dumps(ruleSearch, ensure_ascii=False),
        json.dumps(ruleBookInfo, ensure_ascii=False),
        json.dumps(ruleToc, ensure_ascii=False),
        json.dumps(ruleContent, ensure_ascii=False)
    ]
    
    for rule in all_rules:
        if '@js' in rule or '<js>' in rule:
            issues.append("包含 @js 代码")
            break
        if '##' in rule:
            issues.append("包含正则表达式")
            break
        if '$.' in rule:
            issues.append("包含 JSONPath")
            break
        if 'ajax' in rule.lower() or 'api' in rule.lower():
            issues.append("包含 api/ajax 调用")
            break
        if 'cookie' in rule.lower() or 'token' in rule.lower():
            issues.append("包含 cookie/token")
            break
        if re.search(r'\s+\w+\s+\w+\s+', rule):
            issues.append("包含多层 descendant")
            break
        if ':' in rule and not re.search(r'@(text|href|src|content|html)$', rule):
            issues.append("包含 pseudo/index selector")
            break
    
    # 输出审计结果
    if issues:
        print(f"\nREJECTED_WITH_REASON: {'; '.join(issues)}")
        return False
    else:
        print("\nVERIFIED_V3_CANDIDATE")
        return True

# 主函数
def main():
    book_sources = load_book_sources()
    
    # 选择前 5 个书源进行审计
    top_5 = book_sources[:5]
    verified_count = 0
    
    for source in top_5:
        if audit_source(source):
            verified_count += 1
    
    print(f"\n=== 审计结果 ===")
    print(f"验证通过: {verified_count}/5")

if __name__ == "__main__":
    main()