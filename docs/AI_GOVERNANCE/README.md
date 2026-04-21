# AI Governance Baseline

This README is the repository-owned entry point for the current AI governance baseline.

## Why This Exists

Reader-Core already uses AI-assisted development guidance in `AGENTS.md` and handoff/design documents, but Prompt and AI governance assets were not previously collected under one explicit, repo-owned entry point.

This directory establishes the minimum governance baseline for AI and Prompt usage in Reader-Core so the rules are:

- explicit
- traceable
- handoff-friendly
- consistent with clean-room constraints

## Current Scope

This baseline covers:

- Prompt asset entry requirements
- minimum AI usage rules
- repository expectations for traceability and review

## Out Of Scope In This Phase

This baseline does not create:

- an agent platform
- CI automation for Prompt execution
- external services
- databases
- automatic orchestration
- a full Prompt catalog

## Current Repository State

- Explicit Prompt asset library: not yet established before this directory
- AI development rules: partially present in `AGENTS.md` and design notes
- Prompt governance baseline: now explicitly established here

## Files In This Directory

- `PROMPT_BASELINE.md`
  Defines the minimum template and metadata expected when a Prompt asset is added to this repo.
- `AI_USAGE_RULES.md`
  Defines the minimum usage rules, traceability requirements, and current frozen boundary for AI-related work in Reader-Core.

## Baseline Position

This is a minimum governance baseline only. It exists to make AI and Prompt constraints explicit before any future automation or system expansion is considered.

Prompt baseline requirements must also be followed in pull requests.

## Baseline Status

The current Prompt / AI governance baseline is considered stable.

- Baseline structure has been validated with real prompts
- Change safety has been verified
- No further expansion is planned in this phase

Any future changes must be:
- Justified by concrete use cases
- Evaluated against existing baseline constraints
- Applied incrementally

## 12. Change Classification

Use the following lightweight classification when updating AI governance assets in this directory:

- `baseline_clarification`
  Clarifies existing rules without changing scope.
- `baseline_extension`
  Adds a new governed requirement after explicit review.
- `example_only`
  Updates examples without changing the baseline.
- `process_linking`
  Connects existing governance rules into PR or handoff flow without adding automation.
