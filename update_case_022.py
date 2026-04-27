import yaml

with open('samples/real_world/non_js/regression_matrix.yml', 'r') as f:
    data = yaml.safe_load(f)

for case in data['cases']:
    if case['case_id'] == 'case_022':
        case['status'] = 'blocked'
        case['stage_results'] = {'search': 'blocked', 'detail': 'blocked', 'toc': 'blocked', 'content': 'blocked'}
        case['parser_features_used'] = []
        case['failure_reason'] = ['network_fixture_unavailable', 'no_accessible_real_non_js_source_html']
        case['failure_taxonomy'] = ['network_fixture_unavailable', 'no_accessible_real_non_js_source_html']
        case['last_verified_command'] = 'curl -L --compressed -A "Mozilla/5.0" https://www.deqibook.com'
        case['notes'] = 'BLOCKED - cannot fetch real HTML; tested sites blocked by anti-scraping'

with open('samples/real_world/non_js/regression_matrix.yml', 'w') as f:
    yaml.dump(data, f, allow_unicode=True, default_flow_style=False, sort_keys=False)

print("Updated case_022 to blocked status")