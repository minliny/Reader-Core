import json
import re

# 读取书源数据
with open('samples/booksources/raw_online_dump/all_sources.json', 'r', encoding='utf-8') as f:
    sources = json.load(f)

print(f"Total sources: {len(sources)}")

# 分析使用 text.xxx@href 的书源
text_filter_sources = []
for source in sources:
    # 检查 ruleBookInfo.tocUrl
    rule_book_info = source.get('ruleBookInfo', {})
    if isinstance(rule_book_info, dict):
        toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl')
        if toc_url and 'text.' in toc_url and '@href' in toc_url:
            text_filter_sources.append(source)
    
    # 检查 ruleToc.chapterUrl
    rule_toc = source.get('ruleToc', {})
    if isinstance(rule_toc, dict):
        chapter_url = rule_toc.get('chapterUrl')
        if chapter_url and 'text.' in chapter_url and '@href' in chapter_url:
            text_filter_sources.append(source)

# 去重
unique_sources = []
seen_urls = set()
for source in text_filter_sources:
    url = source.get('bookSourceUrl', '')
    if url not in seen_urls:
        seen_urls.add(url)
        unique_sources.append(source)

print(f"Sources using text.xxx@href: {len(unique_sources)}")

# 分析可被 V3 能力覆盖的候选
v3_compatible_candidates = []
for source in sources:
    is_compatible = True
    reasons = []
    
    # 检查 ruleContent
    rule_content = source.get('ruleContent', {})
    if isinstance(rule_content, dict):
        content_selector = rule_content.get('content')
        if content_selector:
            # 检查是否是 V2 选择器或 V3 能力
            if not (content_selector.startswith('.') or content_selector.startswith('#') or content_selector.startswith('text.')):
                is_compatible = False
                reasons.append("ruleContent not V2/V3 compatible")
        else:
            is_compatible = False
            reasons.append("missing ruleContent")
    else:
        is_compatible = False
        reasons.append("invalid ruleContent format")
    
    # 检查 ruleToc.chapterUrl
    rule_toc = source.get('ruleToc', {})
    if isinstance(rule_toc, dict):
        chapter_url = rule_toc.get('chapterUrl')
        if chapter_url:
            # 检查是否是 V3 能力
            if not (chapter_url == 'a@href' or ' text.' in chapter_url or '@href' in chapter_url):
                is_compatible = False
                reasons.append("chapterUrl not V3 compatible")
        else:
            is_compatible = False
            reasons.append("missing chapterUrl")
    else:
        is_compatible = False
        reasons.append("invalid ruleToc format")
    
    # 检查 ruleBookInfo.tocUrl
    rule_book_info = source.get('ruleBookInfo', {})
    if isinstance(rule_book_info, dict):
        toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl')
        if toc_url:
            # 检查是否是 V3 能力
            if not ('text.' in toc_url or '@href' in toc_url):
                is_compatible = False
                reasons.append("tocUrl not V3 compatible")
        else:
            is_compatible = False
            reasons.append("missing tocUrl")
    else:
        is_compatible = False
        reasons.append("invalid ruleBookInfo format")
    
    # 检查是否有 JS/正则/API/cookie/token
    source_str = json.dumps(source)
    if '@js' in source_str.lower() or 'javascript' in source_str.lower():
        is_compatible = False
        reasons.append("js_rule")
    if '##' in source_str or '$.' in source_str:
        is_compatible = False
        reasons.append("regex_or_jsonpath")
    if 'api' in source_str.lower() or 'ajax' in source_str.lower():
        is_compatible = False
        reasons.append("api_or_ajax")
    if 'cookie' in source_str.lower() or 'token' in source_str.lower() or 'sign' in source_str.lower():
        is_compatible = False
        reasons.append("cookie_or_token")
    
    if is_compatible:
        v3_compatible_candidates.append(source)

print(f"V3 compatible candidates: {len(v3_compatible_candidates)}")

# 输出 Top 10 候选
print("\nTop 10 V3 compatible candidates:")
for i, source in enumerate(v3_compatible_candidates[:10], 1):
    source_name = source.get('bookSourceName', 'Unknown')
    book_source_url = source.get('bookSourceUrl', 'Unknown')
    
    # 分析规则
    rule_book_info = source.get('ruleBookInfo', {})
    rule_toc = source.get('ruleToc', {})
    rule_content = source.get('ruleContent', {})
    
    toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl')
    chapter_url = rule_toc.get('chapterUrl')
    content_selector = rule_content.get('content')
    
    print(f"\n{i}.")
    print(f"source_name: {source_name}")
    print(f"bookSourceUrl: {book_source_url}")
    print(f"ruleBookInfo.tocUrl: {toc_url}")
    print(f"ruleToc.chapterUrl: {chapter_url}")
    print(f"ruleContent.content: {content_selector}")

# 统计使用 text.xxx@href 的具体模式
text_patterns = {}
for source in unique_sources:
    rule_book_info = source.get('ruleBookInfo', {})
    if isinstance(rule_book_info, dict):
        toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl')
        if toc_url and 'text.' in toc_url:
            pattern = toc_url
            text_patterns[pattern] = text_patterns.get(pattern, 0) + 1
    
    rule_toc = source.get('ruleToc', {})
    if isinstance(rule_toc, dict):
        chapter_url = rule_toc.get('chapterUrl')
        if chapter_url and 'text.' in chapter_url:
            pattern = chapter_url
            text_patterns[pattern] = text_patterns.get(pattern, 0) + 1

print("\nText filter patterns:")
for pattern, count in sorted(text_patterns.items(), key=lambda x: -x[1])[:10]:
    print(f"  {pattern}: {count}")