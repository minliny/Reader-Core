# AI Usage Rules

## Current Governance Status

- AI-assisted development guidance already exists in `AGENTS.md`
- AI handoff context already exists in `docs/AI_HANDOFF/`
- Explicit Prompt governance was previously not centralized
- This directory establishes the minimum explicit governance baseline

## Governed Scope

This baseline currently governs:

- Prompt assets that are intentionally reused
- AI-authored or AI-assisted engineering instructions stored in the repository
- minimum traceability expectations for Prompt changes

This baseline does not yet govern:

- automated Prompt execution
- CI-triggered Prompt workflows
- agent runtime infrastructure
- external model routing or service orchestration

## Core Rules

### Prompt Assets Must Be In Repo

If a Prompt is intended for reuse, it must be stored in the repository.

### Prompt Changes Must Be Traceable

Prompt additions and updates must be reviewable through normal repository history.

### Chat Alone Is Not Sufficient

Operational knowledge must not exist only in transient chat when it is meant to be reused.

### No Ungoverned AI Flow

Do not introduce an AI-driven development or review flow without at least a short repository-owned governance note describing:

- purpose
- inputs
- outputs
- constraints
- review expectations

### Clean-Room Still Applies

All AI-assisted work in this repo remains bound by the existing clean-room and no-GPL-carry-over requirements in `AGENTS.md`.

## Current Frozen Boundary

This round establishes a baseline only.

It does not:

- connect Prompt governance to CI
- introduce an auto-execution system
- create a database or external service
- build a complex multi-agent platform
- expand into full operational automation

## Practical Use Rule

When a Prompt becomes important enough to be reused, handed off, or audited, promote it into repository documentation under an explicit governed location instead of leaving it only in conversation history.
