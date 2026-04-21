# Example Prompt: NonJS Sample Regression Triage

## Purpose

Use this Prompt to investigate a failing non-JS sample regression in Reader-Core and propose the smallest safe code or fixture-facing change.

Do not use this Prompt for JS rendering work, platform UI work, or repository-wide refactors.

## Inputs

- failing sample id
- failing command or workflow name, if available
- relevant files under `samples/`
- relevant files under `Core/`
- latest local test or regression output
- current architecture and clean-room constraints from `AGENTS.md`

## Outputs

- a short diagnosis of the first real failure
- the minimal file set that should change
- the expected regression impact
- explicit stop condition if the issue cannot be fixed safely from available evidence

## Constraints

- follow clean-room rules; do not copy or translate external GPL code
- do not change compatibility levels without required evidence flow
- keep the fix minimal and scoped to the identified regression
- do not invent missing sample evidence
- do not expand the task into a broader redesign

## Failure Handling

- if the failing sample or regression output is missing, stop and report the missing input
- if the issue depends on JS capability or unsupported runtime behavior, stop and classify it as outside this Prompt's scope
- if a safe fix cannot be justified from current evidence, stop instead of guessing

## Change Tracking

- Version: v1
- Updated: 2026-04-19
- Note: Added workflow or command context as an optional investigation input
