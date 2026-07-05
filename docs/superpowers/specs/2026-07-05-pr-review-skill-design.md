# PR Review Skill — Design

**Date:** 2026-07-05
**Status:** Approved

## Purpose

Give the repo a committed, vendor-neutral review skill so that when someone asks
to "review the PR", the agent follows a consistent set of AULABS review rules and
posts the result to GitHub the way a human reviewer would — a brief summary plus
inline change-requests with code suggestions on the exact lines.

## Location & wiring

- Skill lives at **`ai/skills/review-pr/SKILL.md`** (reusing the existing `ai/`
  agent-guidance home rather than a new dotted folder). Uses `name:`/`description:`
  frontmatter so it is portable to `.claude/skills/` later.
- **`CLAUDE.md`** gains a small **Skills index** (a `Skill · When to use · File`
  table) with the rule: *"When asked to review a PR, read and follow
  `ai/skills/review-pr/SKILL.md`."* Because `CLAUDE.md`/`AGENTS.md` are always
  loaded, that pointer is the trigger. Future skills add a row to the same table.

## What it checks

The requested list plus AULABS-specific rules. Rather than duplicating project
standards, the skill **defers to `ai/patterns/*` and `ai/architecture.md`** and
treats their anti-patterns as blockers, so it stays in sync with existing guidance.

- **Security & vulnerabilities** — `brakeman`, `bundler-audit`, `importmap audit`;
  `params.permit!`/mass-assignment; SQL string interpolation; secrets; missing
  authorization scoping; `user.role` used for workshop access (should use
  `WorkshopOperator`).
- **N+1 queries** — associations accessed in loops/views without
  `includes`/`preload`/`eager_load`; counts in loops.
- **Duplication** — copy-pasted logic that should become a scope/concern/partial
  (within Rails conventions — no service objects).
- **Code smell** — business logic in controllers; forbidden service/form/interactor
  objects; `default_scope`; generic rescues; `update_columns` on append-only records.
- **AULABS conventions (blockers)** — one `User` model / `WorkshopOperator` access,
  `Admin` separate; Ukrainian i18n in **both** `en.yml` + `uk.yml` (no hardcoded
  strings); **Minitest not RSpec**; migration integrity (`foreign_key`, `null: false`,
  explicit enum hashes, lambda scopes); tests present for new models/controllers.

## How it runs

- **Target** — a PR number/URL if given, else auto-resolved from the current branch
  via the GitHub API. If no PR exists, it prints the same structured report locally.
- **Auth** — keychain token via `git credential fill` (see `github-token-keychain`);
  `gh` CLI is not installed, so all calls go through the REST API with `curl`/`python3`.
- **Tools** — runs `rubocop`, `brakeman`, `bundler-audit`, `importmap audit` and
  notes test status, folding the output into a manual read of the diff.
- **Posting** — one GitHub PR review (`POST /pulls/{n}/reviews`) containing:
  - **1 brief summary** → the review body (verdict + a short "General notes" list for
    any non-line-specific findings).
  - **All line-specific findings** → inline comments anchored to the line/range, each
    a change-request with a ```suggestion``` block where a concrete fix exists.

## Constraint (accepted)

GitHub rejects `REQUEST_CHANGES`/`APPROVE` on your own PR (422), and **bsolomud**
authors these PRs. The review is therefore submitted as **`event: "COMMENT"`** for
self-PRs — the inline change-requests and suggestions are identical to a human's;
only the top-level "Requested changes" banner is absent. When the author is someone
else, it uses `REQUEST_CHANGES` (blockers/warnings) or `APPROVE` (clean), falling
back to `COMMENT` on 422.

## Out of scope

- Auto-applying fixes (review only; suggestions are opt-in via GitHub's UI).
- Opening/merging PRs.
- Mirroring the Skills index into `AGENTS.md` (can be added later if other tools need it).

## Acceptance

- `ai/skills/review-pr/SKILL.md` exists with valid frontmatter and an executable procedure.
- `CLAUDE.md` points to it via a Skills table.
- Asking to "review the PR" posts one review: brief summary + inline suggestions.
