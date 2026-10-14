# Shared UNITE agent instructions

These instructions apply in this repository and when a UNITE workspace or
component `AGENTS.md` explicitly directs you to read them. Resolve documentation links
relative to this repository, even when working in a sibling checkout.

## Load relevant project context

- Read [Project overview](docs/project-overview.md) and
  [Repository map](docs/repository-map.md) to understand the platform and locate
  producers, consumers, shared packages, and draft components.
- Use the topic index in [README.md](README.md#documentation-by-task) to read
  the documents relevant to the task before changing code. Domain, search/access,
  ingestion, processing, analysis, identity, deployment, and migrations each
  have their own document; do not load every detailed document for every task.
- Read the target repository's README, relevant local documentation, and any
  more specific agent instructions. Inspect its Git status before editing.
- When the agent project is the parent source workspace, explicitly read each
  affected repository's `AGENTS.md` before editing it. Keep Git operations and
  build commands scoped to the relevant independent repository.
- Services and libraries are separate Git repositories. Resolve paths from
  repository roots; do not assume a developer's absolute workspace path.
  `unite-meta` is the recommended local name of the organization's `.github`
  repository. Development and installation `unite-env` checkouts may differ.

## Git workflow

- `main` is the release branch. Pushes to `main` run GitHub Actions: service
  repositories build amd64 and arm64 Docker images and push them to GHCR;
  library repositories build NuGet packages and push them to GitHub Packages.
- `dev` is the development branch. Small bug fixes and quick fixes may go to
  `dev` directly. Develop features in a branch created from `dev`; merge it into
  `dev` by pull request, and `dev` into `main` by pull request when ready.
- Library (NuGet) repositories have no `dev` branch; work from `main` there.
- Never work directly in `main` of a repository that has `dev`.
- Local checkouts normally sit on `dev` (or `main` without `dev`). Another
  branch means active or unmerged work, or a branch not switched back after a
  merge; ask before switching. To compare with what is released, use
  `origin/main`; for current development, use `origin/dev`.
- Agents may create local branches and commit to them. Pushing and pull
  requests are done by the owner. Do not push or open pull requests.

## Preserve the project model

- A donor anchors biomedical records. Preserve specimen-level single-sample
  and single-result-set constraints; `Sample.Analysis` means primary assay.
- A saved dataset is a search-criteria preset, whose results depend on current
  data and access. Combined specimen/mutation filters must match the same
  specimen. Preserve server-derived personal project scope, including analysis
  input selection. Worker-token private-project scope is still undefined.
- Submission acceptance, review approval, SQL integration, and indexing are
  different stages. Status meanings and retry behavior depend on task type.
- Integrating a new data type touches nearly every part of the platform; follow
  [Integrating a new data type](docs/integrating-a-data-type.md) and agree the
  answers with the owner before writing code.
- Scientific analyses use Prepare/Process and method-specific file contracts.
  Busy runners are retried; computation failures require manual restart.
- `unite-jobs`, genome liftover, shared HTTP-client extraction, and Docker
  secrets are plans or drafts, not established replacements
  for the current flows. Check each topic document for details and exceptions.

## Work with evidence and shared contracts

- Distinguish owner-confirmed requirements, code-verified behavior, statements
  found only in documentation, and hypotheses awaiting confirmation.
- Do not assume modalities share models, filters, or analysis behavior. Inspect
  the relevant implementation rather than inferring behavior from entities alone.
- For shared contracts/packages, inspect relevant producers and consumers,
  including pinned versions. Local source may differ from deployed packages.
- For schema changes, follow [SQL migrations](docs/sql-migrations.md): settle
  the model and inspect `Up()`/`Down()` for existing-data preservation. Removing
  the last migration is an unpublished local workflow, not a way to rewrite
  deployed migration history. Deployment progress does not prove migration success.

## Coding conventions

Follow [Code style and principles](docs/code-style.md) for new and changed code.

- Normalize text identifiers and references to lowercase wherever possible
  (for example resource names, formats and URLs in submission models), and
  work only with lowercase values in code. This is deliberate: UNITE does not
  support clients that depend on case-sensitive values. Do not remove the
  lowercasing or add case-sensitive handling.

## Validate changes

Follow [Development validation](docs/development-validation.md): review the
code, build, and exercise the affected local scenario. UI changes need manual
portal verification; backend-only changes can use API requests. Routine frontend
work uses `npm run dev` in `unite/Unite.Web/Client` at localhost:8080 while the
portal remains at localhost:443; `npm run build` mainly verifies production/Docker
builds. Vite has its own proxy configuration.

To run a service locally, stop its Docker container (`docker stop unite.<name>`),
run the service natively on the same port, test it directly or through the Vite
UI, then start the container again. Mind its background workers and remove test
data; see [Running a service locally](docs/development-validation.md#running-a-service-locally-instead-of-its-container).

Use focused tests for meaningful computation or custom behavior. Avoid exhaustive
mocked method coverage and implementation-mirroring tests. The owner's practice
of removing temporary tests does not authorize deleting existing tests.
Verify affected consumers and migrations where relevant. Report executed checks
and explicitly identify unavailable manual/integration checks. Documentation-only
changes need link and source-consistency checks, not a platform deployment.

## Track defects

All dkfz-unite repositories, including this one, are public. Defects are
tracked in the team's private Jira (`dkfz-unite.atlassian.net`, project
UNITE-DEV, epic "Known Issues"), not in repository files.

- Never write security-sensitive findings (access-control gaps, unauthenticated
  endpoints, data-exposure paths, exploitable configuration) into any repository
  file, commit message, or pull request. Report them to the owner; after the
  owner confirms, record them as a Bug under the Known Issues epic.
- Record other confirmed defects there as well. Repository documentation may
  describe current behavior neutrally, without pointing at weaknesses.
- Before changing an area, check Jira for known issues that affect it. Do not fix
  a known issue unless the task asks for it.
- Planned changes, refactorings and ideas that are not defects go to the epic
  "Improvements and Ideas" (UND-1059). Check it as well before changing an
  area: it records the direction to follow (for example, grid analyses use
  samples, regions and observations like the CNV profiles grid).

## Skills

Repeated procedures are skills in [`skills/`](skills): `log-defect` (record
defects and ideas in Jira), `run-service-locally` (replace a container with a
local run), `publish-library` (version and publish a shared NuGet library,
then update its consumers), `integrate-data-type` (plan and implement a new
data type end to end), `add-analysis-method` (add or rework an analysis
method with its runner and portal views) and `review-code` (review a change:
functionality first, then code style). Follow a skill when the task matches it; when a procedure is
repeated and not covered, propose a new skill. See
[Skills](docs/shared-documentation.md#skills).

## Maintain shared documentation

Keep common rules here, architecture and workflows in `docs/`, and component
instructions with their repository.

Write anything useful to people, such as API endpoints, data models, formats,
configuration and installation, as general documentation that is readable on
GitHub: the repository's `README.md` and `Docs/` folder. Agent instructions
(`AGENTS.md`) point to those documents instead of repeating them and hold only
agent- and developer-specific details: code layout, where to change things,
pitfalls, version skew, verification steps. When general documentation is
missing or outdated, fix it there rather than in `AGENTS.md`. Update the appropriate document when behavior
changes; avoid copying shared architecture into repository entry points.
Record confirmed answers and supporting references, and resolve stale questions.
During onboarding, ask a few focused questions and state when a component is
understood before moving on. Profile documentation and diagrams are supporting
material and have not all been verified. Never record credentials or identifiable
biomedical records in onboarding documents.
