# UNITE repository instructions

Before changing this repository, read the shared UNITE instructions and
relevant project documentation maintained in
[dkfz-unite/.github](https://github.com/dkfz-unite/.github/blob/main/README.md).

1. Prefer the local shared checkout: `../unite-meta/AGENTS.md`, relative to this
   repository root. A sibling `.github/AGENTS.md` or a user-provided path is also
   valid. Resolve its document links relative to that shared checkout.
2. Read the shared `AGENTS.md`, project overview, repository map, and topic
   documents relevant to the task, following the shared README's task index.
3. If no shared checkout is accessible, use the GitHub versions beginning with
   [shared AGENTS.md](https://github.com/dkfz-unite/.github/blob/main/AGENTS.md).
   If those are unavailable too, report the missing context and proceed only
   with what local documentation/code establishes; do not invent shared rules.
4. Read this repository's README and relevant local docs; inspect Git status.
   More specific instructions here supplement the shared guidance.

Keep common rules in `.github`; keep component details in this repository.

<!--
Component section: fill in when the repository is onboarded, following
unite-composer/AGENTS.md and unite-feed-omics/AGENTS.md. Keep only developer-
and agent-specific details here. API endpoints, data models, formats,
configuration and installation belong in README.md and Docs/ (readable on
GitHub); link to them instead of repeating them, and fix them there when they
are missing or outdated. Never record security-sensitive findings in this file.
Delete sections that do not apply.

## <Component name>

Status: <reviewed with the owner (date) | draft from code reading (date)>.

<One paragraph: what the component is responsible for and what it is not;
links to the relevant shared topic documents.>

### Projects
<Table: project -> contents. Note test projects, or that there are none.>

### Build and run
<Build/run commands, local URL and port, required services, NuGet source,
unite-env application folder.>

### Configuration and API
<Pointer to README (environment variables) and Docs/ (API, models), then
developer-only notes: variables missing from the docs, pitfalls.>

### <Component-specific patterns>
<For example: request handling, submission validation, processing workers.>

### Where to change things
<Table: kind of change -> location, including cross-repository changes.>

### Shared libraries
<Pinned UNITE package versions, skew to watch, local ProjectReference use.>

### CI
<Workflow and what it publishes.>

### Known issues
Defects are tracked in the private Jira; see the shared Track defects section.
-->
