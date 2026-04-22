# Parser V3 Capability Model

**Status:** PREPARE_V3  
**Date:** 2026-04-22  
**Evidence sources:** `tempresource.txt`, `临时导入书源-墨辰.txt`

---

## V2 Retained as Baseline

Parser V2 = **stable subset baseline** / **simple selector core**

V2 covers 4 selector forms and trimming grammar:

| Selector | AST Case |
|----------|----------|
| `.class` | `byClass(String)` |
| `#id` | `byId(String)` |
| `tag` | `byTag(String)` |
| `tag.class` | `byTagAndClass(tag:className:)` |
| `!` suffix | trimming grammar (independent) |

V2 is NOT superseded by V3. V3 extends V2 without rewriting or removing it.  
`KEEP_V2_AS_BASELINE` remains in force.

---

## Why V3 Is Required

Real sample analysis of `tempresource.txt` and `临时导入书源-墨辰.txt` shows:

- `@css:` rule entry appears **346 times** combined (241 in tempresource.txt, 105 in 临时导入书源-墨辰.txt), spanning search / toc / content fields across both files.
- The majority of those rules use selector structures that V2 cannot process: descendant, child, attribute, pseudo-class.
- V2 explicitly rejects these forms (no silent fallback). The gap is real and widespread.
- The compatibility deficit is NOT expressed as "V2 coverage 0%". The correct framing is:
  1. **Rule Syntax Adapter gap** — `@css:` entry prefix and `@SUFFIX` value extraction are not fully normalized.
  2. **Selector Engine gap** — richer selector forms that V2's simple AST does not cover.

**Verdict: PREPARE_V3**

---

## Gap Taxonomy

### Layer 0 — Rule Syntax Adapter

`@css:` is **not a selector type**. It is a Legado rule entry DSL prefix that must be stripped before any selector is passed to the engine. The `@SUFFIX` tokens that follow the selector are Legado value extraction directives — also part of this adapter layer, not of the selector engine.

| Adapter item | Sample evidence | Status |
|---|---|---|
| `@css:` prefix stripping | 346 occurrences | Requires explicit normalization |
| `@text` / `@href` / `@src` / `@html` | Dominant suffixes, all files | Baseline — confirm coverage |
| `@content` | ~30 occurrences; og:meta tags | Needs explicit support |
| `@data-src` | Lazy-load image URLs | Needs explicit support |
| `@ownText` | Text excluding child elements (Jsoup semantic) | Needs explicit support |
| `@textNodes` | Text nodes only (Jsoup semantic) | Needs explicit support |
| `@style` | Background-image URL extraction | Needs explicit support |
| `@all` | Full element content (Jsoup semantic) | Low frequency; needs explicit support |

**Note on Legado native DSL:** Some rules use a non-`@css:` chained selector syntax, e.g., `#info@h1@ownText`, `.class.N@attr`, `tag.index@attr`. This is a **separate Legado DSL** — independent from `@css:`-routed rules. It is **not part of V3 Phase 1** and must be modeled independently in a later stage.

---

### Level 1 — Selector Engine: High Priority

Driven by the highest-frequency real-sample gaps. These directly block search / toc / content extraction for the majority of `@css:` rules.

| Capability | Occurrence estimate | Affected flows |
|---|---|---|
| **descendant selector** (space) | ~130 | search / toc / content |
| **child selector** (`>`) | ~47 | toc / search |
| **attribute selector** | ~70 | search / book_info |
| **`:eq(n)`** (Jsoup pseudo extension) | ~25 | search / book_info |

**Attribute selector variants seen in samples:**
- `[attr=val]` — exact match, e.g., `[property=og:novel:book_name]`
- `[attr^=val]` — prefix match, e.g., `[class^=_searchBookAuthor]`, `[href^='/read/']`
- `[attr$=val]` — suffix match, e.g., `[property$=book_name]`
- `[attr~=val]` — word match, e.g., `[href~=(-|_)\\d+]`, `[itemprop~=chapter]`

**Rationale for `:eq(n)` at Level 1:** In samples, `:eq()` almost never appears standalone. It is embedded in descendant chains, e.g., `.books .dd_box span:eq(0)@text`, `.result-game-item-info p:eq(1) span:eq(1)@text`. Implementing descendant without `:eq()` leaves the majority of Level 1 rules still non-functional.

---

### Level 2 — Selector Engine: Medium Priority

| Capability | Occurrence estimate | Notes |
|---|---|---|
| `:contains(text)` | ~10 | Text-content filter; appears inside descendant chains |
| `:nth-child(n)` / `:nth-of-type(n)` | ~8 | Structural position selection |
| `:first-child` / `:last-child` / `:first-of-type` | ~5 | Head/tail node selection |
| `:not(selector)` | ~3 | Exclusion filter, e.g., `a[href^='/read/']:not([title])` |
| `:has(selector)` | ~6 | Parent-contains filter; Jsoup extension; appears in 临时导入书源-墨辰.txt |

---

### Level 3 — Selector Engine: Low Priority / Defer

| Capability | Occurrence estimate | Notes |
|---|---|---|
| `:containsOwn(text)` | ~2 | Jsoup extension; text-only match excluding children |
| `:matches(regex)` | ~2 | Jsoup extension; regex text match |
| adjacent sibling (`+`) | 1 | Single occurrence, e.g., `small:contains(书籍作者：)+span` |
| multi selector (`,`) | ~2–5 | Comma-separated selector list |

---

## V3 Execution Order

1. **Layer 0 first** — Confirm `@css:` prefix parsing is correct and all `@SUFFIX` tokens are handled. Without this, selector engine improvements are unreachable from real rule inputs.
2. **Level 1 second** — Implement descendant + child + attribute + `:eq(n)` as a bundle. These four are functionally coupled in the real samples.
3. **Level 2 third** — Add remaining pseudo-class forms after Level 1 is stable.
4. **Level 3 last** — Handle low-frequency edge cases and Jsoup-specific extensions.
5. **Legado native DSL** — Model and implement separately; not in V3 Phase 1 scope.

---

## Project Total Goal

Parser V3 is the next stage toward the project's permanent goal: **compatibility with all Legado book sources**.

V3 is not the final endpoint. Gaps remaining after V3 (Legado native DSL, anti-bot, JS network access) continue as compatibility gaps for V4 / later planning.

All extensions must comply with the clean-room principle: no external GPL code, no Legado Android implementation reference.
