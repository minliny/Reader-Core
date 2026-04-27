import json
import re

# 读取书源数据
with open('samples/booksources/raw_online_dump/all_sources.json', 'r', encoding='utf-8') as f:
    sources = json.load(f)

print(f"Total sources: {len(sources)}")

# 筛选规则
def is_valid_selector(selector):
    if not selector:
        return False
    # 检查是否包含禁止的语法
    forbidden_patterns = [
        r'\s+',  # 空格（descendant selector）
        r'>',    # child selector
        r':',    # pseudo selector
        r'\[',   # attribute selector
        r'@js',  # js rule
        r'javascript',
        r'##',   # regex
        r'\$\d', # regex group
        r'\\d',  # regex digit
        r'\.\*', # regex wildcard
        r'[\\s\\S]', # regex any char
    ]
    for pattern in forbidden_patterns:
        if re.search(pattern, selector, re.IGNORECASE):
            return False
    # 检查是否为有效的 V2 选择器或 V3 属性提取
    if '@' in selector:
        parts = selector.split('@')
        if len(parts) != 2:
            return False
        base_selector = parts[0].strip()
        attr = parts[1].strip()
        # 检查属性是否在白名单中
        valid_attrs = ['href', 'src', 'content']
        if attr not in valid_attrs:
            return False
        # 检查基础选择器
        return is_valid_selector(base_selector)
    # 检查 V2 选择器
    v2_pattern = r'^([.#]?[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)?)$'
    return bool(re.match(v2_pattern, selector))

def is_v3_strict_compatible(source):
    # 检查 ruleContent
    rule_content = source.get('ruleContent', {})
    if isinstance(rule_content, str):
        content_selector = rule_content
    else:
        content_selector = rule_content.get('content')
    if not content_selector or not is_valid_selector(content_selector):
        return False
    
    # 检查 ruleToc
    rule_toc = source.get('ruleToc', {})
    if isinstance(rule_toc, str):
        chapter_url = rule_toc
    else:
        chapter_url = rule_toc.get('chapterUrl')
    if not chapter_url:
        return False
    # chapterUrl 必须是 a@href 或 tag.class@href
    if not (chapter_url == 'a@href' or ('.' in chapter_url and '@href' in chapter_url)):
        return False
    if not is_valid_selector(chapter_url):
        return False
    
    # 检查 ruleBookInfo
    rule_book_info = source.get('ruleBookInfo', {})
    if isinstance(rule_book_info, str):
        toc_url = rule_book_info
    else:
        toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl')
    if not toc_url:
        return False
    # 检查 tocUrl 是否有效
    if not is_valid_selector(toc_url):
        return False
    
    return True

# 筛选兼容的书源
compatible_sources = []
for source in sources:
    if is_v3_strict_compatible(source):
        compatible_sources.append(source)

print(f"V3 strict compatible sources: {len(compatible_sources)}")

if len(compatible_sources) > 0:
    # 输出 TOP 5 候选
    print("\nTOP 5 候选：")
    for i, source in enumerate(compatible_sources[:5], 1):
        source_name = source.get('bookSourceName', 'Unknown')
        book_source_url = source.get('bookSourceUrl', 'Unknown')
        
        # 分析为什么兼容
        why_compatible = []
        rule_content = source.get('ruleContent', {})
        if isinstance(rule_content, str):
            content_selector = rule_content
        else:
            content_selector = rule_content.get('content')
        why_compatible.append(f"ruleContent.content 使用: {content_selector}")
        
        rule_toc = source.get('ruleToc', {})
        if isinstance(rule_toc, str):
            chapter_url = rule_toc
        else:
            chapter_url = rule_toc.get('chapterUrl')
        why_compatible.append(f"ruleToc.chapterUrl 使用: {chapter_url}")
        
        rule_book_info = source.get('ruleBookInfo', {})
        if isinstance(rule_book_info, str):
            toc_url = rule_book_info
        else:
            toc_url = rule_book_info.get('tocUrl') or rule_book_info.get('detailUrl')
        why_compatible.append(f"ruleBookInfo.tocUrl 使用: {toc_url}")
        
        # 风险分析
        risk = []
        # 检查是否需要登录
        if source.get('loginUrl') or source.get('isLogin'):
            risk.append("可能需要登录")
        # 检查是否有动态依赖
        if any(keyword in str(source).lower() for keyword in ['token', 'sign', 'cookie', 'ajax', 'api']):
            risk.append("可能存在动态依赖")
        
        print(f"\n{i}.")
        print(f"source_name: {source_name}")
        print(f"bookSourceUrl: {book_source_url}")
        print("why_v3_compatible:")
        for reason in why_compatible:
            print(f"  - {reason}")
        print("risk:")
        for r in risk or ["无明显风险"]:
            print(f"  - {r}")
else:
    print("\nNO_V3_STRICT_COMPATIBLE_SOURCES")