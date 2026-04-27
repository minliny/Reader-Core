#!/usr/bin/env python3
"""
验证和处理 raw_online_dump 目录的脚本
功能：
1. 验证 JSON 合法性
2. 统计每页数量
3. 跨页去重
4. 生成 all_sources.json
5. 生成 schema_summary.json
6. 重写 index.yml
"""

import json
import os
import hashlib
from collections import defaultdict

RAW_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'samples', 'booksources', 'raw_online_dump')
PAGE_FILES = [
    ('page_001.json', '1-20'),
    ('page_002.json', '21-40'),
    ('page_003.json', '41-60'),
    ('page_004.json', '61-80'),
    ('page_005.json', '81-100'),
]


def load_json_file(file_path):
    """加载 JSON 文件并返回数据"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data, None
    except json.JSONDecodeError as e:
        return None, f"Invalid JSON: {e}"
    except Exception as e:
        return None, f"Error loading file: {e}"


def get_stable_hash(obj):
    """获取对象的稳定哈希值"""
    sorted_json = json.dumps(obj, sort_keys=True, ensure_ascii=False)
    return hashlib.md5(sorted_json.encode('utf-8')).hexdigest()


def main():
    print("=== 验证 raw_online_dump 目录 ===")
    
    # 1. 验证每个 page 文件
    page_data = []
    all_records = []
    validation_results = []
    
    for page_file, range_label in PAGE_FILES:
        file_path = os.path.join(RAW_DIR, page_file)
        print(f"\n验证: {page_file}")
        
        if not os.path.exists(file_path):
            validation_results.append({
                'file': page_file,
                'valid': False,
                'error': 'File not found'
            })
            continue
        
        data, error = load_json_file(file_path)
        if error:
            validation_results.append({
                'file': page_file,
                'valid': False,
                'error': error
            })
            continue
        
        if not isinstance(data, list):
            validation_results.append({
                'file': page_file,
                'valid': False,
                'error': 'Not a JSON array'
            })
            continue
        
        # 验证每个对象是否为 dict
        for i, item in enumerate(data):
            if not isinstance(item, dict):
                validation_results.append({
                    'file': page_file,
                    'valid': False,
                    'error': f'Item {i} is not a dictionary'
                })
                break
        else:
            validation_results.append({
                'file': page_file,
                'valid': True,
                'count': len(data),
                'range': range_label
            })
            page_data.append((page_file, range_label, data))
            all_records.extend(data)
    
    # 2. 唯一性验证
    print("\n=== 唯一性验证 ===")
    seen_urls = set()
    seen_names = set()
    seen_hashes = set()
    duplicates = []
    
    for i, record in enumerate(all_records):
        url = record.get('bookSourceUrl')
        name = record.get('bookSourceName', record.get('sourceName'))
        record_hash = get_stable_hash(record)
        
        is_duplicate = False
        duplicate_key = None
        
        if url:
            if url in seen_urls:
                is_duplicate = True
                duplicate_key = f'url:{url}'
            else:
                seen_urls.add(url)
        elif name:
            if name in seen_names:
                is_duplicate = True
                duplicate_key = f'name:{name}'
            else:
                seen_names.add(name)
        else:
            if record_hash in seen_hashes:
                is_duplicate = True
                duplicate_key = f'hash:{record_hash}'
            else:
                seen_hashes.add(record_hash)
        
        if is_duplicate:
            duplicates.append({
                'index': i,
                'key': duplicate_key,
                'record': record
            })
    
    total_records = len(all_records)
    unique_records = total_records - len(duplicates)
    
    print(f"总记录数: {total_records}")
    print(f"唯一记录数: {unique_records}")
    print(f"重复记录数: {len(duplicates)}")
    
    if duplicates:
        print("\n重复记录明细:")
        for dup in duplicates[:5]:  # 只显示前 5 个
            print(f"  索引 {dup['index']}: {dup['key']}")
        if len(duplicates) > 5:
            print(f"  ... 还有 {len(duplicates) - 5} 个重复记录")
    
    # 3. 生成 all_sources.json
    print("\n=== 生成 all_sources.json ===")
    all_sources_path = os.path.join(RAW_DIR, 'all_sources.json')
    with open(all_sources_path, 'w', encoding='utf-8') as f:
        json.dump(all_records, f, ensure_ascii=False, indent=2)
    print(f"生成成功: {all_sources_path}")
    
    # 4. 生成 schema_summary.json
    print("\n=== 生成 schema_summary.json ===")
    field_counts = defaultdict(int)
    for record in all_records:
        for field in record:
            field_counts[field] += 1
    
    field_coverage = {}
    for field, count in field_counts.items():
        field_coverage[field] = {
            'count': count,
            'coverage': count / total_records * 100
        }
    
    schema_summary = {
        'total_records': total_records,
        'unique_records': unique_records,
        'duplicate_records': len(duplicates),
        'field_coverage': field_coverage,
        'top_level_field_count': len(field_counts),
        'generated_at': '2026-04-26'
    }
    
    schema_summary_path = os.path.join(RAW_DIR, 'schema_summary.json')
    with open(schema_summary_path, 'w', encoding='utf-8') as f:
        json.dump(schema_summary, f, ensure_ascii=False, indent=2)
    print(f"生成成功: {schema_summary_path}")
    
    # 5. 修正 index.yml
    print("\n=== 修正 index.yml ===")
    index_yml_path = os.path.join(RAW_DIR, 'index.yml')
    
    # 检查页面是否互不重叠
    disjoint_pages = unique_records == 100 and len(duplicates) == 0
    
    # 检查所有 JSON 是否有效
    all_json_valid = all(v['valid'] for v in validation_results)
    all_arrays_valid = all(v['valid'] for v in validation_results)
    
    yml_content = f'''
dataset: REAL_WORLD_BOOKSOURCE_SNAPSHOT
status: RAW_CACHE_ONLY
source_api_base: https://shuyuan-api.yiove.com/import/book-sources
captured_pages:
  - file: page_001.json
    range: 1-20
  - file: page_002.json
    range: 21-40
  - file: page_003.json
    range: 41-60
  - file: page_004.json
    range: 61-80
  - file: page_005.json
    range: 81-100
total_records: {total_records}
unique_records: {unique_records}
duplicate_records: {len(duplicates)}
aggregate_file: all_sources.json
schema_summary_file: schema_summary.json
usage_policy:
  - raw snapshot only
  - do not use as regression fixture
  - do not generate expected
  - do not mark pass/fail
  - reserved for Parser V3 batch analysis
verification:
  json_valid: {all_json_valid}
  arrays_valid: {all_arrays_valid}
  uniqueness_checked: true
  disjoint_pages_confirmed: {disjoint_pages}
'''
    
    with open(index_yml_path, 'w', encoding='utf-8') as f:
        f.write(yml_content)
    print(f"修正成功: {index_yml_path}")
    
    # 6. 输出验证结果摘要
    print("\n=== 验证结果摘要 ===")
    print("每页验证结果:")
    for result in validation_results:
        if result['valid']:
            print(f"  ✓ {result['file']}: {result['count']} records")
        else:
            print(f"  ✗ {result['file']}: {result['error']}")
    
    print(f"\n总记录数: {total_records}")
    print(f"唯一记录数: {unique_records}")
    print(f"重复记录数: {len(duplicates)}")
    
    print(f"\nall_sources.json 生成: {'✓' if os.path.exists(all_sources_path) else '✗'}")
    print(f"schema_summary.json 生成: {'✓' if os.path.exists(schema_summary_path) else '✗'}")
    print(f"index.yml 修正: {'✓' if os.path.exists(index_yml_path) else '✗'}")
    
    # 检查阻断项
    blocking_issues = []
    if not all_json_valid:
        blocking_issues.append('JSON 验证失败')
    if not all_arrays_valid:
        blocking_issues.append('数组验证失败')
    if len(duplicates) > 0:
        blocking_issues.append('存在重复记录')
    
    if blocking_issues:
        print(f"\n阻断项: {', '.join(blocking_issues)}")
    else:
        print("\n无阻断项")
    
    # 语义结论
    print("\n=== 语义结论 ===")
    if disjoint_pages:
        print("当前快照中 5 个文件互不重叠，共 100 个唯一书源。")
    else:
        print(f"当前快照包含 {unique_records} 个唯一书源，{len(duplicates)} 个重复记录。")
    
    print("\n=== 后续用途说明 ===")
    print("这批数据是：REAL_WORLD_BOOKSOURCE_SNAPSHOT / RAW_CACHE_ONLY")
    print("用途：")
    print("- Parser V3 批量分析")
    print("- 字段覆盖率统计")
    print("- 真实世界兼容性观察")
    print("禁止用途：")
    print("- 不作为 fixture case")
    print("- 不生成 expected")
    print("- 不进入 regression_matrix")
    print("- 不标记 pass/fail")


if __name__ == '__main__':
    main()
