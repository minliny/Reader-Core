# case_023: Project Gutenberg Pride and Prejudice

## Status

```text
SECOND_REAL_PASS_CASE_ESTABLISHED
case_023 = PASS_WITH_KNOWN_DETAIL_FIELD_ISSUES
```

This case proves only that a second real static HTML source can run through the existing non-JS Parser boundary. It does not claim regression baseline readiness.

## Source

- Site: Project Gutenberg
- Detail URL: `https://www.gutenberg.org/ebooks/1342`
- TOC URL: `https://www.gutenberg.org/files/1342/1342-h/1342-h.htm`
- Content URL: `https://www.gutenberg.org/files/1342/1342-h/1342-h.htm`
- Fetch: `curl -L --compressed -A "Mozilla/5.0"` with HTTP 200

## Fixtures

- `fixtures/detail.html`: real fetched ebook page
- `fixtures/toc.html`: real fetched static HTML book page
- `fixtures/content.html`: same real fetched static HTML book page

The HTML is stored as fetched bytes. No synthetic HTML was generated.

## Rules

- `ruleBookInfo: css:h1`
- `ruleToc: css:a@href`
- `ruleContent: css:body`

No Parser source was modified. No JS, API, regex rule, multi-level selector, index selector, or pseudo selector is used.

## Result

| stage | status | evidence |
|---|---|---|
| content-first | PASS | HTTP 200, no block markers, 806295 bytes, continuous text present |
| detail | PASS | `tocUrl` non-empty |
| toc | PASS | 165 extracted links |
| content | PASS | 722016 chars |

## Known Issues

- `tocUrl` uses the current `parseBookInfoResponse` detailURL fallback.
- `toc.chapterTitle == chapterURL` because `ruleToc` is a single rule and cannot emit `title|url` pairs.
- `css:body` captures the full page body, including Project Gutenberg front/back matter.

These are accepted for this phase because the task is to validate whether the current Parser can run a second real static source without Parser changes.
