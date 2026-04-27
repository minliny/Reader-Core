# Real World Booksource Snapshot

## Overview

This document describes the raw online book source snapshot used for real-world parser capability analysis.

## Source

- **Location**: `samples/booksources/raw_online_dump/`
- **Main File**: `all_sources.json`
- **Content**: Approximately 295 unique real book sources collected from online sources

## Purpose

The raw online dump serves as:
- A reference dataset for analyzing real-world book source rule patterns
- A benchmark for evaluating parser capability coverage
- A source of inspiration for creating test cases
- A foundation for understanding the complexity of real-world parsing requirements

## Status

- **REAL_WORLD_BOOKSOURCE_SNAPSHOT_READY**: The snapshot is complete and ready for analysis
- **RAW_CACHE_ONLY**: This is a raw cache of book sources, not a regression test suite

## Restrictions

### Must Not
- **Directly enter regression baseline**: The raw dump contains rules that may be unstable or depend on external services
- **Be directly marked pass/fail**: Many sources use rules beyond current parser capabilities
- **Be used as production book sources**: The dump is for analysis only, not for actual book reading

### Should Only Be Used For
- **Rule pattern analysis**: Understanding common selector patterns and extraction techniques
- **Capability gap identification**: Identifying which parser capabilities are most needed
- **Test case inspiration**: Creating test cases based on real-world patterns
- **Benchmarking**: Evaluating how many real sources current parser capabilities can handle

## Analysis Guidelines

1. **Rule Pattern Analysis**
   - Identify common selector patterns
   - Analyze attribute extraction needs
   - Determine text filtering requirements
   - Document common blockers

2. **Capability Gap Analysis**
   - For each capability, count how many sources would be unblocked
   - Prioritize capabilities based on impact
   - Document specific examples of blocked patterns

3. **Test Case Creation**
   - Extract representative patterns into test cases
   - Focus on patterns that are common and within reach of current capabilities
   - Create both positive and negative test cases

## Sample Analysis Workflow

1. **Load the dump**: Parse `all_sources.json` to extract book source rules
2. **Categorize rules**: Group rules by type (content, toc, search, etc.)
3. **Analyze selectors**: Identify common selector patterns and blockers
4. **Calculate coverage**: Determine how many sources would be compatible with current V3 capabilities
5. **Prioritize enhancements**: Identify which capabilities would unblock the most sources

## Future Use

- **As a reference**: When designing new parser capabilities
- **As a benchmark**: When evaluating parser improvements
- **As a source of test data**: When creating new test cases
- **As a reality check**: To ensure parser development stays grounded in real-world needs

## Important Notes

- The snapshot is a point-in-time capture and may not reflect current status of the book sources
- Many sources in the dump use JavaScript, which is beyond the scope of non-JS parser capabilities
- The dump contains a mix of high-quality and low-quality book sources
- Not all sources in the dump may be functional or reliable