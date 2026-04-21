# Prompt Baseline

## Purpose

This document defines the minimum repository standard for adding a Prompt asset to Reader-Core.

It is a governance template, not a claim that the repository already contains a large Prompt inventory.

## When A Prompt Becomes A Repository Asset

A Prompt must be treated as a repository asset when it is intended to be reused for any of the following:

- implementation work
- code review
- regression execution guidance
- documentation generation
- compatibility investigation
- handoff or operator workflow

Ad hoc chat text is not a governed Prompt asset unless it is intentionally promoted into the repository.

## Minimum Required Fields

Each new Prompt asset should include at least:

### Name

A stable name that can be referenced in docs, reviews, and handoff.

### Purpose

What task the Prompt is for, and what it is not for.

### Inputs

What context, files, parameters, or sample data the Prompt expects.

### Outputs

What kind of output is expected, including artifact type or acceptance shape when relevant.

### Constraints

Hard boundaries such as:

- clean-room requirements
- repo ownership boundaries
- forbidden dependency directions
- required samples / regression evidence
- no GPL code carry-over

### Failure Handling

What the operator or agent should do if the Prompt cannot be executed safely or cannot produce a reliable result.

### Change Tracking

How revisions are tracked. At minimum:

- version or date marker
- short change note in git history or adjacent notes

## Minimum Template

```md
# <Prompt Name>

## Purpose
- ...

## Inputs
- ...

## Outputs
- ...

## Constraints
- ...

## Failure Handling
- ...

## Change Tracking
- Version: v1
- Updated: YYYY-MM-DD
- Note: ...
```

## Repository Expectations

- Prompt assets must live in the repository, not only in chat history
- Prompt changes must be reviewable in git
- Prompt text must not conflict with `AGENTS.md`
- Prompt assets that affect compatibility or regression work must stay aligned with sample-driven workflow expectations

## Current Baseline Limit

This document defines the minimum shape only. It does not require a full Prompt registry or execution system in this phase.
