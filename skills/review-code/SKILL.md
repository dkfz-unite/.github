---
name: review-code
description: Review a UNITE code change (working tree, branch or pull request) - functionality and cross-service effects first, then UNITE's code style and principles - and report verified findings ordered by severity, keeping security findings out of public places. Use when asked to review code, a diff, a branch or a pull request in a UNITE repository.
---

# Review a UNITE code change

Review in the team's order of priority: **does it work correctly** (including
for the other services that depend on it), then **is it written the UNITE
way**. Rules: `unite-meta/docs/code-style.md`; project rules:
`unite-meta/AGENTS.md`.

## 1. Understand the change

- Determine the scope: uncommitted changes, a branch against its base
  (`origin/dev`, or `origin/main` in repositories without `dev`), or a pull
  request. Read the whole diff.
- Find the intent: the task, the Jira issue, the commit messages. If the intent
  is unclear, ask before judging.
- Read the repository's `AGENTS.md` and the shared topic documents for the
  area (domain, search and access, ingestion, analysis, ...). Check Jira
  ("Known Issues", "Improvements and Ideas") for the area: a change may
  conflict with a planned direction or touch a known defect.

## 2. Functionality (most important)

Read the changed code in context: callers, callees, and consumers in other
repositories. Check at least:

- **Correctness**: logic, edge cases (empty, null, missing references,
  repeated submissions), error paths. Follow "Errors and exceptions" in the
  style guide: expected outcomes are return values, validation happens once
  and early.
- **Access scope**: every new read path of biomedical data goes through
  personal search criteria; user identity comes from the token, never from the
  request; admin endpoints require role `Root`; project visibility rules hold
  (see `docs/search-and-access.md`, `docs/domain.md`).
- **Data**: write semantics (upsert, replace, merge) match
  `docs/domain.md`; migrations preserve existing data (`Up()`/`Down()`); index
  model changes need reindexing.
- **Contracts**: shared packages (`unite-data`, `unite-indices`, ...) and their
  pinned versions in consumers; claims, criteria, file contracts between
  analysis service, runners and portal; feed routes used by Data Source and the
  portal.
- **Conventions with behavior**: lowercase normalization of identifiers;
  configuration (required settings fail clearly, optional ones default).
- **Performance and resources** where data is large: queries (`AsNoTracking`,
  no loading of whole tables, no N+1), memory, aggregation limits.
- **Documentation**: `README.md`, `Docs/` and `AGENTS.md` updated when
  behavior, API, configuration or models change.

Verify every functional finding by reading the code path or reproducing it
(e.g. with the `run-service-locally` skill). Drop findings you cannot support;
mark the ones that are plausible but unverified as such.

## 3. Style and principles

Check against `docs/code-style.md`: common sense and KISS over ceremony,
abstractions only where they pay off, shared code for repeated patterns;
file structure and member order, two blank lines between groups;
naming (namespace as part of the name, short names, `entity` in queries);
DI rules (helpers used in one place created with `new`); records for data,
classes for behavior; arrays over lists; async only where the API is async;
routes and attributes; Vue Options API and single quotes in changed code.

Report style only for code the change adds or modifies. Do not ask to rewrite
untouched code; older deviations are fixed when touched.

## 4. Report

- Findings ordered by severity: **blocking** (wrong behavior, data loss,
  access or security problems, broken consumers), **should fix**, **style**,
  **notes/questions**.
- Each finding: `file:line`, what is wrong, the concrete consequence, a
  suggested fix.
- Say explicitly what was verified, what was not (e.g. UI needs a manual
  check), and what looks good when it matters.
- **Security findings** go only to the owner in the conversation, never into
  pull request comments, commit messages or repository files; afterwards
  follow the `log-defect` skill.
- Do not change the code unless asked. Defects outside the change go to Jira
  through `log-defect`, not into the review.
