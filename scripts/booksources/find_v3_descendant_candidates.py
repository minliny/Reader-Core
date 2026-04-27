import json
import re

# 读取书源数据
with open('samples/booksources/raw_online_dump/all_sources.json', 'r', encoding='utf-8') as f:
    sources = json.load(f)

print(f"Total sources: {len(sources)}")

# 筛选规则
# 严格语法校验
def is_strict_valid(selector):
    if not selector:
        return False
    
    # 检查是否是裸属性
    if selector == 'href' or selector == 'src':
        return False
    
    # 检查是否是 text filter
    if selector.startswith('text.'):
        return False
    
    # 检查是否包含 index
    if 'a.0' in selector or '.0' in selector:
        return False
    
    # 检查是否包含中文
    if any(ord(c) > 127 for c in selector):
        return False
    
    # 检查是否包含禁止的字符
    forbidden_chars = ['>', ':', '[', ']']
    for char in forbidden_chars:
        if char in selector:
            return False
    
    # 检查是否是多层 descendant（超过一个空格）
    spaces = selector.count(' ')
    if spaces > 1:
        return False
    
    # 检查是否是一层 descendant 或简单选择器
    if spaces == 1:
        parts = selector.split(' ')
        parent = parts[0]
        child_part = parts[1]
        
        # 检查 child 是否包含 @attr
        if '@' in child_part:
            child, attr = child_part.split('@', 1)
            if not child or not attr:
                return False
            # 检查 attr 是否在白名单中
            valid_attrs = ['href', 'src', 'content', 'text', 'html']
            if attr not in valid_attrs:
                return False
        else:
            child = child_part
        
        # 检查 parent 是否是有效的 V2 选择器
        if not is_valid_v2_selector(parent):
            return False
        
        # 检查 child 是否是简单 tag
        if not is_simple_tag(child):
            return False
    else:
        # 检查是否是有效的 V2 选择器或 V3 attribute 提取
        if '@' in selector:
            base, attr = selector.split('@', 1)
            if not base or not attr:
                return False
            # 检查 attr 是否在白名单中
            valid_attrs = ['href', 'src', 'content', 'text', 'html']
            if attr not in valid_attrs:
                return False
            # 检查 base 是否是有效的 V2 选择器
            if not is_valid_v2_selector(base):
                return False
        else:
            if not is_valid_v2_selector(selector):
                return False
    
    return True

def is_valid_v2_selector(selector):
    if not selector:
        return False
    # 检查是否是 V2 选择器格式
    # .class, #id, tag, tag.class
    v2_pattern = r'^([.#]?[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)?)$'
    return bool(re.match(v2_pattern, selector))

def is_simple_tag(tag):
    simple_tags = {
        'a', 'abbr', 'address', 'article', 'aside', 'audio', 'b', 'blockquote', 'body', 'br',
        'button', 'canvas', 'caption', 'cite', 'code', 'col', 'colgroup', 'dd', 'del', 'details',
        'dfn', 'dialog', 'div', 'dl', 'dt', 'em', 'embed', 'fieldset', 'figcaption', 'figure',
        'footer', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hgroup', 'hr', 'html',
        'i', 'iframe', 'img', 'input', 'ins', 'kbd', 'label', 'legend', 'li', 'link', 'main',
        'map', 'mark', 'math', 'menu', 'menuitem', 'meta', 'meter', 'nav', 'noscript', 'object',
        'ol', 'optgroup', 'option', 'output', 'p', 'param', 'pre', 'progress', 'q', 'rb', 'rp',
        'rt', 'rtc', 'ruby', 's', 'samp', 'script', 'section', 'select', 'small', 'source',
        'span', 'strong', 'sub', 'sup', 'table', 'tbody', 'td', 'template', 'textarea', 'tfoot',
        'th', 'thead', 'time', 'title', 'tr', 'track', 'u', 'ul', 'var', 'video', 'wbr'
    }
    return tag.lower() in simple_tags

def analyze_source(source):
    reasons = []
    is_compatible = True
    
    # 检查 ruleContent
    rule_content = source.get('ruleContent', {})
    if isinstance(rule_content, str):
        content_selector = rule_content
    else:
        content_selector = rule_content.get('content') if isinstance(rule_content, dict) else None
    
    if content_selector:
        if not is_strict_valid(content_selector):
            reasons.append(f"invalid_rule_content: {content_selector}")
            is_compatible = False
    else:
        reasons.append("missing_ruleContent")
        is_compatible = False
    
    # 检查 ruleToc.chapterUrl
    rule_toc = source.get('ruleToc', {})
    if isinstance(rule_toc, str):
        chapter_url = rule_toc
    else:
        chapter_url = rule_toc.get('chapterUrl') if isinstance(rule_toc, dict) else None
    
    if chapter_url:
        if not is_strict_valid(chapter_url):
            reasons.append(f"invalid_chapter_url: {chapter_url}")
            is_compatible = False
    else:
        reasons.append("missing_chapter_url")
        is_compatible = False
    
    # 检查 ruleBookInfo.tocUrl
    rule_book_info = source.get('ruleBookInfo', {})
    if isinstance(rule_book_info, str):
        toc_url = rule_book_info
    else:
        toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl') if isinstance(rule_book_info, dict) else None
    
    if toc_url:
        if not is_strict_valid(toc_url):
            reasons.append(f"invalid_toc_url: {toc_url}")
            is_compatible = False
    
    # 检查是否有 JS/正则/API/cookie/token
    source_str = json.dumps(source)
    if '@js' in source_str.lower() or 'javascript' in source_str.lower():
        reasons.append("js_rule")
        is_compatible = False
    if '##' in source_str or '$.' in source_str:
        reasons.append("regex_or_jsonpath")
        is_compatible = False
    if 'api' in source_str.lower() or 'ajax' in source_str.lower():
        reasons.append("api_or_ajax")
        is_compatible = False
    if 'cookie' in source_str.lower() or 'token' in source_str.lower() or 'sign' in source_str.lower():
        reasons.append("cookie_or_token")
        is_compatible = False
    
    return is_compatible, reasons

# 分析所有书源
compatible_sources = []
rejection_stats = {
    "multi_level_descendant": 0,
    "child_selector": 0,
    "pseudo_selector": 0,
    "attribute_selector": 0,
    "js_rule": 0,
    "regex_or_jsonpath": 0,
    "api_or_ajax": 0,
    "cookie_or_token": 0,
    "invalid_selector": 0,
    "missing_chapter_url": 0,
    "missing_ruleContent": 0,
    "other": 0
}

for source in sources:
    is_compatible, reasons = analyze_source(source)
    if is_compatible:
        compatible_sources.append(source)
    else:
        for reason in reasons:
            if reason in rejection_stats:
                rejection_stats[reason] += 1
            else:
                rejection_stats["other"] += 1

print(f"V3 descendant compatible sources: {len(compatible_sources)}")

print("\nRejection statistics:")
for reason, count in sorted(rejection_stats.items(), key=lambda x: -x[1]):
    if count > 0:
        print(f"  {reason}: {count}")

print("\nTOP 10 候选：")
for i, source in enumerate(compatible_sources[:10], 1):
    source_name = source.get('bookSourceName', 'Unknown')
    book_source_url = source.get('bookSourceUrl', 'Unknown')
    
    # 分析为什么兼容
    why_compatible = []
    rule_content = source.get('ruleContent', {})
    if isinstance(rule_content, str):
        content_selector = rule_content
    else:
        content_selector = rule_content.get('content')
    why_compatible.append(f"ruleContent.content: {content_selector}")
    
    rule_toc = source.get('ruleToc', {})
    if isinstance(rule_toc, str):
        chapter_url = rule_toc
    else:
        chapter_url = rule_toc.get('chapterUrl')
    why_compatible.append(f"ruleToc.chapterUrl: {chapter_url}")
    
    rule_book_info = source.get('ruleBookInfo', {})
    if isinstance(rule_book_info, str):
        toc_url = rule_book_info
    else:
        toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl')
    why_compatible.append(f"ruleBookInfo.tocUrl: {toc_url}")
    
    print(f"\n{i}.")
    print(f"source_name: {source_name}")
    print(f"bookSourceUrl: {book_source_url}")
    print("why_v3_compatible:")
    for reason in why_compatible:
        print(f"  - {reason}")

if len(compatible_sources) == 0:
    print("\n没有找到 V3 descendant 兼容的书源")