# Case 021: snapd.net

## Source
- bookSourceName: snapd.net
- bookSourceUrl: https://m.snapd.net/read/114355/
- source_type: non_js

## Fixture Status

### detail.html
- **Status**: ✅ Real, parseable
- **HTTP Status**: 200 OK
- **Content**: Book detail page with title, author, cover, intro, and chapter list
- **Selectors used**: css:.books, css:.book_info, css:.book_last

### toc.html
- **Status**: ❌ Blocked by anti-scraping
- **HTTP Status**: 302 redirect
- **Redirects to**: /user/verify.html
- **Content**: "加载中..." anti-bot verification page

### content.html
- **Status**: ❌ Blocked by anti-scraping
- **HTTP Status**: 302 redirect
- **Redirects to**: /user/verify.html
- **Content**: "加载中..." anti-bot verification page

## Pipeline Status
- **search**: blocked (async JS required)
- **detail**: pass (real HTML available)
- **toc**: blocked (anti-scraping redirect)
- **content**: blocked (anti-scraping redirect)

## Notes
This case is retained as a real-world example of anti-scraping protection.
It demonstrates that even when detail pages are accessible, subsequent
page requests (toc, content) may be protected by verification redirects.

This case is NOT counted in real_valid_pass_cases as it cannot complete
the full pipeline (detail → toc → content).

## Failure Taxonomy
- anti_scraping_response: toc and content pages redirect to verification
- missing_search_html: search page uses async JS, not captured

## Baseline Exclusion
- Not counted in real_valid_cases
- Not counted in real_valid_pass_cases
- Marked as "partial" in regression_matrix