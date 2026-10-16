# UNITE project overview

Status: purpose, audience, and core domain explained by the owner; onboarding
continues. Last updated: 2026-10-12.

## Purpose

UNITE integrates biomedical data of different modalities into one system,
preserving as many meaningful connections between those data as possible.
It provides search and filtering across the integrated data.

Users can use filters to create datasets, referred to as cohorts when discussing
donors. Users can then analyze a single dataset or compare multiple datasets,
depending on the available analysis method.

These statements were confirmed by the project owner during the onboarding
conversation on 2026-10-06. A saved dataset is a named preset of search criteria;
for donors, those criteria define a cohort. The preset is stored in MongoDB
`user-data.datasets`, and re-running it evaluates the current matching data.

The initial focus is cancer research. The integration model is intended to be
useful beyond that focus, but this does not imply every workflow already
supports other research areas.

## Users

The primary audience is researchers, bioinformaticians, and physicians familiar
with the relevant biomedical research domain.

Administrators are expected often to be bioinformaticians as well. Their
responsibilities include reviewing data submissions, installing the platform,
and configuring data sources. These audience descriptions differ from the
active software permissions `Data.Read`/`Data.Write` and the root administrator
role; see [Identity and lifecycle](identity-and-lifecycle.md).

## Core domain

The donor is the central entity and represents anonymized patient data. All
donor-associated biomedical data must belong to a donor. Images attach to the
donor; biological specimens also attach to the donor and provide the material
for digital omics samples. Specimens can be related in a derivation hierarchy.

The owner deliberately limits each specimen to one sample of a given modality
and one active result set of each result kind for the specimen, independent of
assay origin. WGS and WES occupy the same DNASeq slot. CNVProfiles, for example,
can come from DNA sequencing or methylation arrays but represent the same
specimen-level data. Repeated uploads merge or replace results rather than
expose parallel result runs; the intended merge/replace behavior per result
kind is in the [domain model](domain.md#intentional-constraints).

The sample's current `Analysis` means primary assay; renaming it to Primary
Assay is planned. It is distinct from a downstream analysis of a dataset.
A donor's membership in any public project makes its data visible, including
when it also belongs to a private project.

See [Domain model](domain.md) for terminology, rationale, evidence, and open
questions. Private project visibility is under development; RNA gene fusions
and non-human donors are future directions.

## Modalities and workflows

The project owner confirmed that handling differs by data type and modality.
Some workflows are similar; others differ substantially. A common abstraction
must not be taken as proof that all modalities behave identically.

The owner explanation and [organization profile](../profile/README.md) identify
these broad groups:

- Donor/patient data, including clinical and treatment data.
- Imaging metadata and radiomics features.
- Specimens and their hierarchy, including materials, cell lines, organoids,
  xenografts, and associated data.
- Omics data, including variants, CNV profiles, methylation, gene expression,
  single-cell gene expression, and protein expression.

The main relationships have been explained by the owner and checked in selected
model classes. Full implementation coverage, especially for individual assay
types, has not yet been reviewed.

## Data ingestion and integration modes

Data enters through the portal UI for simpler, smaller submissions or through
feed APIs. `unite-data-source` discovers configured files using sample sheets
or custom crawlers, submits data/metadata to feeds, and serves external files.

Tight/deep integration stores structured values that can be indexed and
filtered. Loose integration registers metadata, availability, and URLs; file
contents stay at the source and are retrieved for analysis preparation. Their
availability can be searchable, but remote values are not integrated search
criteria. Avoid unnecessary copies and relocation of original files.

The standard review path validates the request, stages accepted data in
MongoDB, creates a SQL submission task, and awaits administrator approval before
worker integration and indexing. Task creation differs from writing submitted
domain records. See [Data ingestion](data-ingestion.md) for stages, examples,
and implementation notes.

## Processing and indexing

Donor, image, and specimen submissions write SQL domain data and create indexing
tasks. Indexing workers read SQL records, build documents, and write them into
Elasticsearch; successful indexing tasks are removed.

New variants take an additional asynchronous annotation route through the
Ensembl VEP wrapper before indexing. Gene/protein expression is enriched via
Ensembl Data during submission processing, then indexed.

Variants without transcript consequences are still indexed. Fully neutral CNV
without LOH remain in SQL but are excluded from indexing. Search indexes are
therefore not an exhaustive copy of SQL records.

Internal submission-processing errors trigger another attempt. Administrator
rejection uses `Rejected` in current code, with the reason in `Comment`;
rejected submissions are retained and planned cleanup is not implemented.
The API-issued submission number supports status and rejection-reason tracking.

Task status meanings depend on the work type; not every task passes through or
remains stored with every status. The owner confirmed `review=false` is currently
unused and exists for possible future trusted automated submitters.
See [Processing pipeline](processing-pipeline.md) for states, routes, and actual
project names.

## Search and access

`unite-indices` supplies document models, Elasticsearch context services, and
the search library; `unite-composer` exposes indexed data through its HTTP API.
Separate collections carry compact navigation fields. Cross-reference search
filters related collections, aggregates linked IDs, and uses them to constrain
the target collection. Each stage accumulates constraints for the following
stages; positive ID constraints are intersected, and an empty required result
ends the search immediately. For example, donors can be selected by their mutations,
and mutations by their donors' diagnosis. Combined specimen/mutation criteria
must match the same specimen.

The backend wraps frontend `SearchCriteria` in `PersonalSearchCriteria` using
authenticated user claims and restricts the scope to accessible projects. The
owner confirmed that this scope also governs analysis data selection.
Private-project enforcement is still being completed; see
[Search and access](search-and-access.md#personal-criteria-and-project-visibility).

## Saved datasets and portal

Users save search criteria with a name and description. The datasets page
shows saved presets, their criteria, matching data amounts, and modality
availability, which helps determine available analysis methods. The saved
model stores criteria rather than a separate membership snapshot.

The UI lives in `unite/Unite.Web/Client` (Vue.js). The ASP.NET server hosts the
frontend and acts as a reverse proxy to services; Composer persists presets
in MongoDB. See [Datasets and portal](datasets-and-portal.md) for the flow and
code entry points.

## Analysis workflow

The frontend offers methods compatible with selected datasets' available data
and opens a method-specific dialog. `unite-analysis` records dataset criteria,
options, and analysis metadata in MongoDB `user-data.analyses`, with a SQL task
for processing. Prepare resolves current matching samples/data and writes
formatted inputs to a shared volume. Process runs the method, prepares outputs
and an archive, and completes the task.

Many computations run in separate R/Python containers through the
`unite-commands` web wrapper. A busy runner refuses the request and the task
remains eligible for retry. Preparation/computation errors become `Failed` and
require manual restart. Analyses and their remaining files are kept until the
user deletes them. File layouts and archive contents are method-specific.

Ordinary results are loaded and visualized in the browser, commonly with
Plotly.js. Scell builds a large AnnData/H5AD dataset; a local Cell-x-Gene fork
displays it in a per-dataset viewer container through a portal proxy and iframe.
See [Analysis pipeline](analysis-pipeline.md) for phases, status distinctions,
file contracts, repository mapping, and viewer lifecycle.

## Identity and account lifecycle

`unite-identity` authenticates users and issues signed JWTs with permissions.
`UNITE_INSTANCE_PUBLIC=true` allows registration without an access list;
private instances require the administrator to add a user's email. This
instance setting differs from visibility of public/private projects.

Active permissions are `Data.Read` and `Data.Write`; the configured root
administrator can manage the platform. Admin-issued worker JWTs support service
access, currently used by `unite-data-source`. Their scope for private projects
is explicitly not yet defined. Internal services validate JWT signatures with
the shared `UNITE_API_KEY` and apply their authorization policies.

Identity cleans expired sessions and inactive accounts; account deletion also
removes saved datasets and analyses. Analysis-file cleanup differs by deletion
path and is incomplete; the retention setting in unite-env currently conflicts
with Identity's unit (days). See
[Identity and lifecycle](identity-and-lifecycle.md) for confirmed rules and
selected implementation details.

## Installation and deployment

`unite-env` provides Docker Compose configuration and scripts for local and
server installation. `programs/` contains databases/search infrastructure and
optional management tools; `applications/` contains UNITE services, scientific
runners, and migration applications. The owner runs scripts through `sh` from
their containing directories.

The full deployment uses `sh deploy.sh` from `scripts/`; component directories
support published-image deployment, building a remote branch, or building copied
local source from the folder in `UNITE_SOURCE_PATH_PREFIX` (set in `.env.local` or the shell profile). During local development,
libraries can be connected through sibling `ProjectReference` entries; Docker
verification uses newly published NuGet versions from library `main` pushes.
Ensembl database and VEP cache setup are separate steps. Servers are managed through SSH, with portal
HTTP/HTTPS access and no direct developer-machine access to their databases.

Configuration comes from the shared `.env` and `.env.secrets` files, passed to
Docker Compose by all scripts; moving secrets to Docker secrets is planned.
See [Deployment and development](deployment-and-development.md) for current
behavior, script differences, and source references.

## Repository organization

Domain and identity SQL models use code first, with explicit context mapping
classes and separate databases (`unite_data` and `unite_identity`). Their
migrations live in `unite-data-migrations` and `unite-identity-data-migrations`.
The owner generates migrations after settling the model, reviews `Up()`/`Down()`,
applies them locally, and checks services before publishing. Dedicated migration
containers apply pending migrations at startup during deployment. See
[SQL migrations](sql-migrations.md) for the development loop and layout details.

- Project repositories belong to
  [dkfz-unite on GitHub](https://github.com/dkfz-unite), as confirmed by the owner.
- Source repositories are checked out as independent sibling Git repositories
  in a developer-selected workspace directory. Branching, CI and agent Git
  permissions are in the shared [Git workflow](../AGENTS.md#git-workflow).
- This repository is `.github` on GitHub and `unite-meta` locally.
- The owner maintains two `unite-env` checkouts: one alongside source repositories
  for editing, and another in the installation location.

An initial [Repository and dependency map](repository-map.md) describes the
main services, independently published packages, helper libraries, source/plugin
repositories, and missing local checkouts. It is not a complete organization
inventory or a deployed version manifest.

`Unite.Data` and `Unite.Data.Context` are separate NuGet packages, as are
`Unite.Indices`, `Unite.Indices.Context`, and `Unite.Indices.Search`. Feeds use
SQL/Mongo/Elasticsearch libraries for their integration/indexing work;
Composer and Analysis also use the higher-level search package. General
Essentials and TSV utilities are shared across consumers. Extracting the
duplicated `JsonHttpClient` into `unite-essentials-http` is planned.

The owner confirmed two draft repositories: `unite-jobs` for moving the task
system into a dedicated database, and `unite-genome-liftover` for converting
supported omics data between separate GRCh37/GRCh38 installations. These are
future directions, not replacements for the documented current flows.

The owner identified [unite-data](https://github.com/dkfz-unite/unite-data) as the
main repository describing domain data types, entities, and their relationships.
Use it as the first code entry point when discussing the biomedical data model.

[unite-indices](https://github.com/dkfz-unite/unite-indices) is the corresponding
entry point for index document models, index services, and the search engine.

## Existing documentation

- [Organization profile](../profile/README.md): supported data and functionality.
- [Architecture](../profile/architecture.md): documented components and stores.
- [Data structure](../profile/data-structure.md): documented entities and links.

The profile and data-structure pages now include the owner-confirmed domain
model. Feed documentation links have been updated to paths that exist in the
local source checkouts. A complete implementation audit, validation of remote
links, and review of existing SVG diagrams remain pending. The architecture
page now also describes data-source hosting, the standard review pipeline, and
the main installation workflow. Detailed operational validation remains pending.

## Questions for the next discussion

The main ingestion/processing routes and cross-reference search are documented
in [Processing pipeline](processing-pipeline.md) and
[Search and access](search-and-access.md). Saved-preset behavior and portal
structure are documented in [Datasets and portal](datasets-and-portal.md).
The main analysis path, retry/failure policy, retention, and Scell viewer are
documented in [Analysis pipeline](analysis-pipeline.md). Identity modes,
permissions, tokens, and account lifecycle are covered in
[Identity and lifecycle](identity-and-lifecycle.md). Installation and script
modes are covered in [Deployment and development](deployment-and-development.md).
The model/mapping split and SQL workflow are covered in [SQL migrations](sql-migrations.md).
The initial [Repository and dependency map](repository-map.md) is now available.
The owner's code review, build, manual UI/API checks, and focused unit-test
practice are documented in [Development validation](development-validation.md).
Repository-level entry points now connect the available local checkouts to the
shared instructions; see [Shared documentation setup](shared-documentation.md).

### Identity and deployment

- Worker-token project scope is an open design decision. Verify current
  claim/package compatibility and account-file cleanup with their components.
- Missing helper/runner/Cell-x-Gene checkouts and source-specific crawler
  details remain for targeted work; use the initial repository map for navigation.
- Detailed service-update timing, migration success checks, and backup/rollback
  procedures remain for an operational review; the main development loop is documented.

Remaining access-control and feed implementation details are recorded in the
[domain model](domain.md#open-questions) for their respective component reviews.

Continue documenting components one at a time in the order that makes their
responsibilities and dependencies clear.
