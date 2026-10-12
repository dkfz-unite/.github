---
name: log-defect
description: Verify and record a UNITE defect or improvement idea in the team's private Jira (project UND "UNITE-DEV", epics "Known Issues" and "Improvements and Ideas"), keeping security-sensitive findings out of the public repositories. Use when a bug, security weakness or improvement is found or reported, or when asked to log, file or track an issue.
---

# Log a defect or improvement

All dkfz-unite repositories are **public**. Defects and ideas are tracked only in
the private Jira: `dkfz-unite.atlassian.net`, project **UND** (UNITE-DEV).
Rules: `unite-meta/AGENTS.md`, "Track defects".

| Kind | Issue type | Parent epic |
| --- | --- | --- |
| Defect (wrong behavior, missing cleanup, broken path) | Bug | UND-1029 "Known Issues" |
| Planned change, refactoring, idea, design direction | Task | UND-1059 "Improvements and Ideas" |

Labels: `security` for security-relevant issues, `critical` when the owner says
so (or for clear data exposure); otherwise none.

## Steps

1. **Check Jira first** for an existing issue on the same area (JQL text
   search). Extend it instead of creating a duplicate.
2. **Verify in code** before logging: read the actual path end to end (caller,
   endpoint, service, consumer). Note what is verified and what is inferred.
   Do not log unverified suspicions as bugs.
3. **Security-sensitive findings** (access-control gaps, unauthenticated
   endpoints, data exposure, exploitable configuration):
   - never write them into a repository file, commit message, pull request or
     public doc, not even as a neutral note;
   - tell the owner in the conversation and wait for confirmation;
   - until confirmed, keep them only in the untracked local file
     `security-review-pending.md` in the workspace root (not a Git repository);
     after logging, move the entry to its "logged" list with the issue key.
4. **Ask the owner** whether it is a bug, intended behavior or an idea, when
   that is not obvious. Intended behavior is documented, not logged.
5. **Create the issue** with this description structure:
   - **Current behavior**: repository, files, classes and endpoints involved;
     what happens.
   - **Effect**: the concrete consequence for users or data.
   - **Expected** (owner, date): the confirmed intended behavior.
   - **Fix** (or fix options): where and how, as a suggestion.
   - Related issues by key.
   Title format: `<Component>: <what is wrong>`, e.g. `Identity: login does not
   update LastActive`.
6. **Update the docs** where behavior is described: the component `AGENTS.md`
   or shared topic document may reference the issue key next to a neutral
   description of current behavior (never for security findings). Record owner
   decisions made while discussing the issue.
7. **Report** the issue key and link to the user.

## Notes

- One issue per independent defect; group only small related defects of one
  component when the owner prefers.
- Do not fix a logged issue unless the task asks for it.
