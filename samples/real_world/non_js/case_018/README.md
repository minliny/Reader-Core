# Case 018 - Non-JS Book Source

## Overview
This is a test case for non-JS book source parsing.

## Book Source
- **Name**: Case-018-Non-JS
- **URL**: http://case018.local
- **Type**: Non-JS
- **Login Required**: No

## Test Stages
- [x] Search
- [x] Detail
- [x] TOC
- [x] Content

## Parser Features Used
- simple_selector_class

## Fixtures
- `fixtures/search.html` - Search results page
- `fixtures/detail.html` - Book detail page
- `fixtures/toc.html` - Table of contents page
- `fixtures/content.html` - Chapter content page

## Expected Results
- `expected/search_result.json` - Expected search results
- `expected/detail_result.json` - Expected book detail
- `expected/toc_result.json` - Expected table of contents
- `expected/content_result.json` - Expected chapter content