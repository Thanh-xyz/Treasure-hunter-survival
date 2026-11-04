---
name: git-flow
description: Manage safe feature-branch and pull-request flow for the Treasure Hunter multi-worktree project after implementation, testing, and review are complete.
---

# Git Flow

## Input

- Reviewed feature diff and test evidence.
- Confirmed integration strategy and target branch.

## Procedure

1. Fetch/prune remotes and inspect branches, PRs, authentication, worktrees, and
   the other agent's active branch.
2. Confirm the feature branch was created from the approved base.
3. Verify only owned/approved files changed and run `git diff --check`.
4. Commit with a conventional message, push the feature branch, and open a PR to
   the approved integration branch.
5. Never merge into `main` without human approval and integration validation.

## Output

Commit/PR identifiers, target branch, checks, conflicts, and integration status.

## Acceptance Criteria

- Authenticated account is `Thanh-xyz`.
- No direct-main commit, force push, history rewrite, or other-agent commit edit.
- PR reports actual test status.

## Failure Handling

Stop on missing integration branch, authentication failure, unexpected remote
changes, conflicts, or ownership violations.
