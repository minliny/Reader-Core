# Parser V3 Current Boundary

## V2 Capabilities (Stable)

### Supported
- `.class` selectors
- `#id` selectors
- `tag` selectors
- `tag.class` selectors

### Unsupported
- Attribute extraction
- Descendant selectors
- Text filter
- Regex
- Pseudo selectors
- Multi-level selectors

## V3 Capabilities (Partial)

### V3_ATTRIBUTE_EXTRACTION_MINIMAL

#### Supported
- `selector@href`
- `selector@src`
- `selector@content`
- `selector@text`
- `selector@html`

#### Unsupported
- Attribute fallback to parent/child/sibling
- Complex attribute selectors
- Dynamic attribute extraction

### V3_DESCENDANT_SELECTOR_MINIMAL

#### Supported
- One-level parent child: `.parent child`
- One-level parent child with attribute: `.parent child@href`

#### Unsupported
- Multi-level descendant selectors
- Child selectors (`>`)
- Adjacent sibling selectors (`+`)
- General sibling selectors (`~`)

### V3_TEXT_FILTER_MINIMAL

#### Supported
- `text.xxx` (text matching)
- `text.xxx@attr` (text matching with attribute extraction)
- Parent scoped text filter: `.parent text.xxx@attr`
- Minimal clickable ancestor attribute extraction

#### Unsupported
- Sibling fallback
- Descendant fallback
- Arbitrary ancestor fallback
- Regex text matching
- Exact text matching
- Multi-text conditions

## Real-world Status

### Current Blocker
1. **JavaScript Dependencies**
   - `@js` / `<js>` in rules
   - AJAX calls for content loading

2. **Complex Selectors**
   - Multi-level descendant selectors
   - Index selectors (e.g., `:nth-child`)
   - Pseudo selectors

3. **Dynamic Content**
   - API calls for data
   - Token-based authentication
   - Sign-based request verification

4. **Advanced Extraction**
   - Regex-based content processing
   - JSONPath for data extraction
   - Complex replace rules

5. **Non-static Rules**
   - Rules that depend on runtime state
   - Rules that require cookie management
   - Rules that use device-specific parameters

## Current Limitations

- **Parser V3** only has partial capabilities and cannot handle the full range of real-world book source rules
- **Raw online dump** contains ~295 real book sources, but most use rules beyond current V3 capabilities
- **No FIRST_REAL_PASS_CASE** has been established yet
- **Real-world regression** is still in early stages with only partial cases attempted

## Next Steps

1. **Focus on FIRST_REAL_PASS_CASE**
   - Select a simple site with minimal JS dependencies
   - Manually save real HTML for detail/toc/content
   - Write rules using only current V3 capabilities
   - Establish a complete pipeline that works end-to-end

2. **Capability Expansion (Future)**
   - Base expansion decisions on raw_online_dump analysis
   - Prioritize capabilities that would unblock the most real sources
   - Maintain compatibility with existing V2/V3 semantics