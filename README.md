# UNITE project onboarding

Shared project context and agent instructions for the
[DKFZ UNITE organization](https://github.com/dkfz-unite).
The remote repository is named `.github`; its recommended local checkout name
is `unite-meta`, alongside the other UNITE source repositories.

## Start here

Read [Project overview](docs/project-overview.md) for the platform's purpose,
then [Repository map](docs/repository-map.md) to locate its components and
packages. Agents also read [AGENTS.md](AGENTS.md) for shared working rules.
Continue with the documents relevant to the task below.

## Documentation by task

| Task or question | Document |
| --- | --- |
| Understand donors, projects, specimens, assays, and domain constraints | [Domain model](docs/domain.md) |
| Submit data through UI/API or configure a data source | [Data ingestion](docs/data-ingestion.md) |
| Understand review, tasks, SQL integration, annotation, and indexing | [Processing pipeline](docs/processing-pipeline.md) |
| Change filters, cross-reference search, or project visibility | [Search and access](docs/search-and-access.md) |
| Work on saved datasets, modality summaries, or the Vue portal | [Datasets and portal](docs/datasets-and-portal.md) |
| Prepare/run analyses, handle results, or use the Scell viewer | [Analysis pipeline](docs/analysis-pipeline.md) |
| Work on authentication, permissions, LDAP/SMTP, or account cleanup | [Identity and lifecycle](docs/identity-and-lifecycle.md) |
| Run locally, deploy services, build branches, or develop shared libraries | [Deployment and development](docs/deployment-and-development.md) |
| Change SQL models, mappings, or migrations | [SQL migrations](docs/sql-migrations.md) |
| Integrate a new data type (modality, result kind) end to end | [Integrating a new data type](docs/integrating-a-data-type.md) |
| Find repositories, packages, dependencies, or draft components | [Repository map](docs/repository-map.md) |
| Write or review code (style, naming, principles) | [Code style and principles](docs/code-style.md) |
| Decide how to verify a change | [Development validation](docs/development-validation.md) |
| Look up or record confirmed defects | Private Jira, see [Track defects](AGENTS.md#track-defects) |
| Connect a repository or teammate to shared instructions | [Shared documentation setup](docs/shared-documentation.md) |
| Use or add skills (step-by-step procedures) | [`skills/`](skills), see [Skills](docs/shared-documentation.md#skills) |

The main biomedical model is in
[unite-data](https://github.com/dkfz-unite/unite-data), starting with
`Unite.Data/Entities` and `Unite.Data.Context/Mappers`.
[unite-indices](https://github.com/dkfz-unite/unite-indices) defines index models,
Elasticsearch infrastructure, and search.

The existing [organization profile](profile/README.md),
[architecture](profile/architecture.md), and
[data structure](profile/data-structure.md) provide supporting documentation.
Their diagrams and implementation details have not all been checked against
current code; topic documents identify confirmed behavior and open questions.

## Local layout

```text
<source-workspace>/
├── AGENTS.md               # workspace entry point; template maintained here
├── CLAUDE.md               # contains only `@AGENTS.md`, for Claude Code
├── .claude/skills/         # links to unite-meta/skills (Claude Code)
├── .agents/skills/         # links to unite-meta/skills (Codex)
├── unite-meta/             # this repository; remote name: .github
├── unite/
├── unite-composer/
├── unite-identity/
├── unite-env/              # source checkout for development
└── ...
```

The workspace name and absolute path are developer-specific. A separate
`unite-env` installation checkout may exist outside the source workspace.

The usual agent project is the parent source workspace containing all checkouts.
Its root `AGENTS.md` directs the agent to these shared instructions, then to the
instructions in each affected component. Component files can hold local
clarifications and also support working directly in an individual repository.
Each connected repository has a README link for people. Shared guidance is
maintained here; it is not automatically inherited from a sibling repository.
See [Shared documentation setup](docs/shared-documentation.md) for cloning,
other checkout layouts, and the workspace/component entry-point templates.

## Onboarding status

The main domain, ingestion/review, processing/indexing, search/access, datasets,
analysis, identity, deployment/development, SQL migration, and validation flows
are documented. Entry points have been added to the currently available local
repositories. Publishing these changes to their individual GitHub repositories
is still required for other team members to receive them through Git.

Onboarding continues through targeted component reviews. Reviewed with the
owner so far: `unite-composer`, `unite-feed-omics`, `unite-indices`, and
`unite-analysis` with its local runners (DEG, DEP, DM, PCAM), the portal
(`unite`), `unite-identity`, the images, specimens and donors feeds, and
`unite-data-source`. Worker-token
project scope, missing checkouts, the analysis template, access-control checks,
and operational procedures remain open where noted in the topic documents.
