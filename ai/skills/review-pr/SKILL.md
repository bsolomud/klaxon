---
name: review-pr
description: >-
  Use when asked to review a pull request, review a PR, review the current
  branch's changes, or "code review" work in this repo (klaxon / AULABS).
  Runs a full review — security, vulnerabilities, N+1 queries, duplication,
  code smell, and AULABS conventions — and posts it to GitHub as one PR
  review: a brief summary plus inline change-requests with code suggestions
  on the exact lines.
---

# PR Review — klaxon / AULABS

Review a pull request like a careful senior engineer, then post the result to
GitHub as a **single review**: one brief summary comment, plus an inline
change-request on each relevant line — with a code **suggestion** whenever you
can propose the concrete fix.

## When to use

Any request like "review the PR", "review this PR", "review my changes",
"review the branch", "do a code review". If a PR number or URL is given, review
that; otherwise resolve the PR from the current branch.

## Principles

- **Review the diff, understand the whole.** Read the changed files in full for
  context, but only comment on lines that are part of this PR's changes.
- **Be specific and actionable.** Every line-specific finding is an inline
  comment on the exact line(s). Prefer a ```suggestion``` block over prose.
- **One brief summary.** A sentence or two of overall verdict. Findings that
  are not tied to a specific line go in a short "General notes" list inside the
  summary — plain prose, no suggestion block.
- **Signal over noise.** Only raise what a human reviewer would. Mark true
  nits as 🟢 and keep them few.
- **Defer to the repo's own rules.** Treat anti-patterns in `ai/patterns/*` and
  violations of `ai/architecture.md` as blockers. Do not invent new standards
  or suggest abstractions the project forbids (no service/form/interactor objects).

## Severity legend

- 🔴 **Blocker** — bug, security issue, data-integrity risk, or a hard
  anti-pattern from `ai/patterns/*` / `ai/architecture.md`.
- 🟡 **Warning** — code smell, N+1, duplication, missing test/i18n; should fix.
- 🟢 **Nit** — style/polish; optional.

---

## Step 1 — Identify the target

```bash
# owner/repo from the origin remote
read OWNER REPO < <(git remote get-url origin \
  | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##; s#/# #')

# GitHub token from the macOS keychain (see memory: github-token-keychain)
TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill 2>/dev/null | sed -n 's/^password=//p')

gh_api() { curl -sS -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" "$@"; }
```

Determine the PR number:

1. If the user gave a number or URL, use it (`PR=<n>`).
2. Otherwise resolve it from the current branch:

   ```bash
   BRANCH=$(git branch --show-current)
   PR=$(gh_api "https://api.github.com/repos/$OWNER/$REPO/pulls?head=$OWNER:$BRANCH&state=open" \
     | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d[0]["number"] if d else "")')
   ```
3. If `PR` is empty, there is no open PR → go to **Step 6 (local fallback)**.

## Step 2 — Gather context

```bash
gh_api "https://api.github.com/repos/$OWNER/$REPO/pulls/$PR" > /tmp/pr.json
HEAD_SHA=$(python3 -c 'import json;print(json.load(open("/tmp/pr.json"))["head"]["sha"])')
AUTHOR=$(python3 -c 'import json;print(json.load(open("/tmp/pr.json"))["user"]["login"])')
ME=$(gh_api https://api.github.com/user | python3 -c 'import sys,json;print(json.load(sys.stdin)["login"])')

# changed files + per-file patch (defines which lines are commentable)
gh_api "https://api.github.com/repos/$OWNER/$REPO/pulls/$PR/files?per_page=100" > /tmp/pr_files.json
```

- Read the changed files in full (working tree or `git show`) so you understand
  context, not just the hunks.
- **Only lines inside a file's `patch` hunks are commentable.** Added/context
  lines use `side: "RIGHT"`; removed lines use `side: "LEFT"`. Anchoring a
  comment to a line not in the diff returns 422 — put such findings in the
  summary's "General notes" instead.

## Step 3 — Run the tools

Run these and fold the results into your findings (map each to a line where possible):

```bash
bin/rubocop $(git diff --name-only origin/master...HEAD -- '*.rb' 2>/dev/null)  # style / some smells
bin/brakeman --no-pager        # security static analysis
bin/bundler-audit              # gem CVEs
bin/importmap audit            # JS dependency advisories
```

Also check that new models/controllers have Minitest coverage in `test/`
(do not add tests to `spec/` — that RSpec dir is legacy). You need not run the
full suite; note anything obviously untested or failing.

## Step 4 — Review checklist

Go through the diff against every item. Cite `ai/patterns/*` / `ai/architecture.md`
when a rule comes from there.

**Security & vulnerabilities**
- `brakeman` warnings; `bundler-audit` / `importmap audit` advisories.
- `params.permit!` or skipped strong params; mass-assignment of sensitive attrs.
- SQL built by string interpolation; unsafe `find_by_sql`/`where("...#{}")`.
- Secrets/keys/tokens committed.
- Queries not scoped to the authenticated principal (`ai/patterns/authorization.md`).
- Workshop access checked via `user.role` instead of `WorkshopOperator`.

**N+1 queries**
- Associations touched in a loop/view without `includes`/`preload`/`eager_load`.
- Per-row counts/queries where a scope, `counter_cache`, or eager load fits.

**Duplication**
- Copy-pasted validations/queries/logic that should be a scope, concern, or
  shared partial — using Rails conventions, not new abstractions.

**Code smell**
- Business logic in controllers (keep them thin; fat models).
- Service/form/interactor objects (forbidden here).
- `default_scope`; `update_columns` on append-only records; generic `rescue`.
- `where(...).first` where `find_by` fits; missing guard clauses.

**AULABS conventions (blockers)**
- One `User` model; no Operator model; `Admin` kept separate.
- User-facing strings via `t()` with keys in **both** `en.yml` **and** `uk.yml`;
  no hardcoded UI text.
- Migrations: `foreign_key: true` on references, `null: false` on required
  columns, explicit integer enum hashes, lambda scopes.
- Optimistic locking on status transitions where required; missing
  validations/DB indexes; plain correctness/logic bugs.

## Step 5 — Assemble findings

For each finding decide: `path`, the exact `line` (or `start_line`→`line` range),
severity, a one-line explanation, and — when you can — a `suggestion`.

- A ```suggestion``` block **replaces exactly the anchored line(s)**, so its
  content must be the full replacement for those lines (match indentation).
- Line-specific → inline comment. Non-line-specific → "General notes" in the summary.

## Step 6 — Post the review

Build and submit **one** review with `python3` (avoids shell-escaping issues with
multi-line bodies). Fill `summary` and `comments` from Step 5:

```bash
python3 - "$OWNER" "$REPO" "$PR" "$HEAD_SHA" "$AUTHOR" "$ME" "$TOKEN" <<'PY'
import json, sys, urllib.request, urllib.error
owner, repo, pr, sha, author, me, token = sys.argv[1:8]

summary = """**Review — request changes.** Solid overall; a few items to address before merge.

**General notes** (not line-specific):
- Add `uk.yml` entries for the new flash messages."""

comments = [
    # single line + code suggestion
    {"path": "app/models/car.rb", "line": 12, "side": "RIGHT",
     "body": "🔴 **Blocker — VIN needs a length + uniqueness check.**\n"
             "```suggestion\n  validates :vin, uniqueness: true, allow_nil: true, length: { is: 17 }\n```"},
    # multi-line range, prose only
    {"path": "app/controllers/cars_controller.rb", "start_line": 8, "start_side": "RIGHT",
     "line": 12, "side": "RIGHT",
     "body": "🟡 **Warning — business logic in the controller.** Move this into `Car` "
             "(fat model, thin controller) per ai/patterns/controllers.md."},
]

# Event: self-PRs can only COMMENT (GitHub 422s REQUEST_CHANGES/APPROVE on your own PR).
if author == me:
    event = "COMMENT"
elif any("🔴" in c["body"] or "🟡" in c["body"] for c in comments):
    event = "REQUEST_CHANGES"
else:
    event = "APPROVE"

def post(ev):
    payload = {"commit_id": sha, "body": summary, "event": ev, "comments": comments}
    req = urllib.request.Request(
        f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr}/reviews",
        data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"},
        method="POST")
    return urllib.request.urlopen(req)

try:
    r = post(event)
    print("Posted:", json.load(r).get("html_url"))
except urllib.error.HTTPError as e:
    body = e.read().decode()
    if e.code == 422 and event != "COMMENT":
        print("422 (likely self-PR); retrying as COMMENT")
        r = post("COMMENT")
        print("Posted:", json.load(r).get("html_url"))
    else:
        print("Error", e.code, body)
PY
```

After posting, report the review URL and a short recap of what you flagged.

## Step 7 — Local fallback (no PR)

If no PR exists, review `git diff origin/master...HEAD` (or the working tree) and
print the **same structure** to the terminal: the brief summary, then per-file
findings with `file:line`, severity, and suggested diffs. Offer to open a PR if
the user wants it posted.
