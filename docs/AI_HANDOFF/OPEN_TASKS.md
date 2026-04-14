# Reader-Core Open Tasks

## Current Status (2026-04-14)

Reverse split extraction complete. Reader-Core is independently initialized.

## Active Tasks

- Validate Core CI runs cleanly in the new independent repo (trigger core-swift-tests, fixture-toc-regression, policy-regression)
- Tag next Reader-Core release after CI baseline confirmed in this repo

## Optional / Cosmetic

- Rename Reader-for-iOS remote to Reader-iOS on GitHub (pending user action)
- Upgrade Reader-iOS dependency from `exact: "0.1.0"` to `upToNextMinor` after baseline

## Governance

- compat_matrix ownership: Reader-Core
- failure taxonomy ownership: Reader-Core
- Core frozen contract: owned by Reader-Core — Reader-iOS must not modify
