#!/usr/bin/env python3
import json
import re
import os

# 读取书源数据
def load_book_sources():
    file_path = "samples/booksources/raw_online_dump/all_sources.json"
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

# 检查规则是否符合 V3 能力要求
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
    
    return True

# 检查 text filter 语义是否符合要求
def is_valid_text_filter(rule):
    if not rule:
        return True
    
    # 检查是否包含 JS
    if '@js' in rule or '<js>' in rule or 'java.ajax' in rule:
        return False
    
    return True

# 检查书源是否符合 V3 能力要求
def is_compatible(book_source):
    # 检查 ruleContent
    rule_content = book_source.get('ruleContent', {})
    if isinstance(rule_content, str):
        rule_content = {}
    content = rule_content.get('content', '')
    next_content_url = rule_content.get('nextContentUrl', '')
    
    if content and not is_valid_selector(content):
        return False, "ruleContent.content 不符合 V3 能力要求"
    if next_content_url and not is_valid_selector(next_content_url):
        return False, "ruleContent.nextContentUrl 不符合 V3 能力要求"
    
    # 检查 ruleToc
    rule_toc = book_source.get('ruleToc', {})
    if isinstance(rule_toc, str):
        rule_toc = {}
    chapter_url = rule_toc.get('chapterUrl', '')
    
    if chapter_url and not is_valid_selector(chapter_url):
        return False, "ruleToc.chapterUrl 不符合 V3 能力要求"
    
    # 检查 ruleBookInfo
    rule_book_info = book_source.get('ruleBookInfo', {})
    if isinstance(rule_book_info, (list, str)):
        rule_book_info = {}
    toc_url = rule_book_info.get('tocUrl', '')
    
    if toc_url and not is_valid_selector(toc_url):
        return False, "ruleBookInfo.tocUrl 不符合 V3 能力要求"
    
    # 检查 text filter 语义
    if 'text.' in (content or ''):
        if not is_valid_text_filter(content):
            return False, "ruleContent.content 不符合 text filter 语义要求"
    if 'text.' in (next_content_url or ''):
        if not is_valid_text_filter(next_content_url):
            return False, "ruleContent.nextContentUrl 不符合 text filter 语义要求"
    if 'text.' in (chapter_url or ''):
        if not is_valid_text_filter(chapter_url):
            return False, "ruleToc.chapterUrl 不符合 text filter 语义要求"
    if 'text.' in (toc_url or ''):
        if not is_valid_text_filter(toc_url):
            return False, "ruleBookInfo.tocUrl 不符合 text filter 语义要求"
    
    return True, ""

# 主函数
def main():
    book_sources = load_book_sources()
    compatible_sources = []
    淘汰_reasons = {}
    
    for source in book_sources:
        is_compat, reason = is_compatible(source)
        if is_compat:
            compatible_sources.append(source)
        else:
            if reason not in 淘汰_reasons:
                淘汰_reasons[reason] = 0
            淘汰_reasons[reason] += 1
    
    # 输出结果
    print(f"可用书源数量: {len(compatible_sources)}")
    print()
    
    # 输出 Top 5 候选
    print("Top 5 候选:")
    top_5 = compatible_sources[:5]
    for i, source in enumerate(top_5, 1):
        print(f"\n{i}. source_name: {source.get('bookSourceName', 'Unknown')}")
        print(f"   bookSourceUrl: {source.get('bookSourceUrl', 'Unknown')}")
        print(f"   why_compatible: 符合 V3 完整能力要求")
        print(f"   risk: 低")
    
    # 输出淘汰原因统计
    print("\n淘汰原因统计:")
    for reason, count in 淘汰_reasons.items():
        print(f"- {reason}: {count}")
    
    # 找到 FIRST_REAL_PASS_CASE 候选
    print("\nFIRST_REAL_PASS_CASE 候选:")
    if compatible_sources:
        first_candidate = compatible_sources[0]
        print(f"source_name: {first_candidate.get('bookSourceName', 'Unknown')}")
        print(f"bookSourceUrl: {first_candidate.get('bookSourceUrl', 'Unknown')}")
        print(f"why_compatible: 符合 V3 完整能力要求，优先选择")
        print(f"risk: 低")

if __name__ == "__main__":
    main()