# Repository, package, and dependency map

Last updated: 2026-10-12.

This initial map combines owner explanations with local README, project-file,
and selected code/Compose reads. The workspace is a partial set of independent
repositories, not a complete organization inventory or a verified deployed
version set. Repository names, NuGet packages, running services, and database
access describe different relationships.

## How to navigate

Start with the relevant repository's README and `Docs/`, then check its current
`.csproj`, configuration, and callers. README dependencies can be incomplete or
stale. A `PackageReference` gives a versioned library dependency; a
`ProjectReference` connects source projects. HTTP clients and Compose hosts
describe service dependencies. A package reference alone does not establish
permission to read every database, project, or record.

When changing a contract, inspect its producer and consumers. Local source may
differ from the versions pinned in consuming projects or deployed images. See
[Deployment and development](deployment-and-development.md) for local references,
package publication, and image/source build modes.

## Shared NuGet packages

Several repositories publish multiple independently named NuGet packages.
Do not treat a repository name as a single package or running service.

| Repository | Package | Responsibility and package relationship |
| --- | --- | --- |
| `unite-data` | `Unite.Data` | Plain biomedical entities/enums/relationships |
| `unite-data` | `Unite.Data.Context` | SQL context, explicit mapping, and data services; depends on `Unite.Data` and `Unite.Essentials` |
| `unite-indices` | `Unite.Indices` | Elasticsearch document models |
| `unite-indices` | `Unite.Indices.Context` | Elasticsearch connection/read/write/delete services; depends on `Unite.Indices` |
| `unite-indices` | `Unite.Indices.Search` | Criteria, filters, cross-reference search and collection services; depends on `Unite.Indices.Context` and `Unite.Essentials` |
| `unite-identity-data` | `Unite.Identity.Data` | Identity entities, context, mapping, and data services in one current project |
| `unite-cache` | `Unite.Cache` | Generic MongoDB supporting-data repository/model/connection options |
| `unite-essentials` | `Unite.Essentials` | General extensions and utilities, including enum aliases/conversion, expressions, collections, dates, and entities |
| `unite-essentials-tsv` | `Unite.Essentials.Tsv` | Owner's TSV parser/writer: models to/from TSV, including nested models; used directly by feeds, Composer, Analysis, Data Source, and crawlers |
| `unite-essentials-http` | Planned shared HTTP utility | Intended home for reusable `JsonHttpClient`; extraction is planned, not an established current dependency |

The local `unite-data` projects show `Unite.Essentials` in **Context**, rather
than the plain `Unite.Data` project. Consumers may also reference it directly.
The package table describes ownership and selected dependencies, not every
third-party dependency.

### Package versions per consumer

Latest published versions on 2026-10-07: `Unite.Data`/`Unite.Data.Context`
12.10.33, `Unite.Indices*` 13.10.20, `Unite.Identity.Data` 4.3.0, `Unite.Cache`
1.3.0, `Unite.Essentials` 1.6.0. `Unite.Cache` targets .NET 6; all other
repositories target .NET 8. Consumers pin explicit versions, so skew is normal
and must be checked when changing a shared contract (**bold** = behind latest,
from `origin/main` project files, rechecked 2026-10-12):

| Consumer | Data.Context | Indices | Cache | Essentials | Essentials.Tsv |
| --- | --- | --- | --- | --- | --- |
| composer (`Unite.Composer`) | 12.10.33 | Search 13.10.20 | **1.0.3** | – | 4.2.0 |
| composer (`Unite.Composer.Download`) | **12.10.32** | – | – | – | 4.2.0 |
| analysis | **12.10.14** | Search **13.10.19** | **1.0.3** | – | 4.2.0 |
| identity | **12.10.20** | – | 1.3.0 | 1.6.0 (`Unite.Post`) | – |
| data-migrations | **12.10.20** | – | – | – | – |
| feed-donors | **12.10.20** | Context **13.10.4** | **1.0.0** | – | **4.1.0** |
| feed-images | 12.10.33 | Context **13.10.0** | **1.0.0** | – | 4.2.0 |
| feed-specimens | 12.10.33 | Context **13.10.0** | **1.0.0** | **1.4.0** | 4.2.0 |
| feed-omics | 12.10.33 | Context **13.10.0** | **1.2.3** | – | 4.2.0 |
| data-source | – | – | – | **1.4.0** | 4.2.0 |
| `Unite.Data.Context`, `Unite.Indices.Search` | – | – | – | **1.4.0** | – |

`unite-identity-data-migrations` uses `Unite.Identity.Data` 4.3.0.

`unite-essentials-tsv` and `unite-essentials-http` are not cloned in this
workspace. TSV's role and nested-model support are owner-confirmed; its package
references/usages are visible in the consumers, but implementation internals
have not been inspected. HTTP utility extraction is recorded from the owner's
plan. Duplicate current `JsonHttpClient` classes are present in
`unite-composer/Unite.Composer/Clients/` and
`unite-feed-omics/Unite.Omics.Annotations/Clients/`. Do not assume the planned
package already replaces those copies.

`Unite.Cache` is a **library**, not a cache server or a substitute for
Elasticsearch. Its `CacheRepository<T>` uses MongoDB and is specialized by
consumers for staged submissions and user data. Concrete database/collection
selection and lifecycle belong to those consumers; the name "cache" does not
mean every record is temporary or may be discarded.

## Main applications and infrastructure access

The table describes the reviewed service's combined projects and runtime
responsibility. Database names here distinguish domains; access to the same
PostgreSQL server does not mean every application reads the identity database.
User/project authorization remains a separate concern.

| Repository | Main UNITE libraries | Storage and service relationships |
| --- | --- | --- |
| `unite-feed-donors` | `Data.Context`, `Indices.Context`, `Cache`, `Essentials.Tsv` | Domain PostgreSQL integration/tasks; Mongo staged submissions; Elasticsearch indexing |
| `unite-feed-images` | Same core set as donors feed | Same storage pattern for image data |
| `unite-feed-specimens` | Same core set plus direct `Essentials` | Same storage pattern for specimens and related data |
| `unite-feed-omics` | `Data.Context`, `Indices.Context`, `Cache`, `Essentials.Tsv` | Same storage pattern plus HTTP calls to Ensembl Data/VEP for enrichment/annotation |
| `unite-composer` | `Data.Context`, `Indices.Search`, `Cache`, `Essentials.Tsv` | Domain PostgreSQL; Elasticsearch search; Mongo datasets/submission review; Ensembl Data client and additional identity/feed clients |
| `unite-analysis` | `Data.Context`, `Indices.Search`, `Cache`, `Essentials.Tsv` | Domain PostgreSQL/tasks; Elasticsearch selection; Mongo analysis records; source-file HTTP downloads, shared analysis volume, scientific runners, and Cell-x-Gene orchestration |
| `unite-identity` | `Identity.Data`, `Data.Context`, `Cache`; `Essentials` in mail helper | Identity PostgreSQL, domain SQL analysis-task cleanup, Mongo saved-user-data cleanup; JWT/session/account lifecycle |
| `unite` | No UNITE NuGet references in current portal project | Hosts Vue and proxies internal services/viewers; clients consume their APIs |
| `unite-data-source` | `Essentials`, `Essentials.Tsv` | Source filesystem, persistent tracking files, UNITE feed HTTP APIs and hosted-resource HTTP; no direct portal SQL/search/cache package dependency in the current project |
| `unite-ensembl-data` | Internal `Ensembl.Data` project | Web wrapper around local Ensembl MySQL reference data |
| `unite-ensembl-vep` | Web project | VEP process and filesystem reference cache; used by omics annotation |
| `unite-commands` | Web project | Runs configured scientific commands over HTTP with a process limit; normally embedded in runner containers |

Package names in this table omit the common `Unite.` prefix. Dependencies span
projects in each repository: e.g. a feed's SQL writer uses `Data.Context`, its
indexing project adds `Indices.Context`, and its Web project adds Mongo/TSV and
references the other projects. Feeds do not currently reference the higher-level
`Indices.Search` package as their indexing dependency.

The owner described feeds, Composer, and Analysis as having access to the
platform's main stores where their work requires it. The reviewed core pattern
is PostgreSQL + MongoDB + Elasticsearch. Omics accesses Ensembl through wrapper
APIs rather than treating the reference MySQL database as another normal feed
store. Shared database capabilities do not imply that one component performs
all of another component's responsibilities.

## Installation and migrations

Identity's `Unite.Post` project is an internal SMTP mail helper currently used
for password-reset email. Its LDAP identity service checks credentials against
the organization's directory while UNITE still manages its user/session/JWT
and permission flow. See
[Identity providers and SMTP](identity-and-lifecycle.md#identity-providers-and-smtp-mail)
for current options (LDAP runs alongside the standard login).

| Repository | Responsibility |
| --- | --- |
| `.github`, locally `unite-meta` | Shared onboarding/agent instructions and organization profile documentation |
| `unite-env` | Platform Compose configuration and deployment/build scripts; development and installation checkouts may differ |
| `unite-data-migrations` | Domain database migrations and startup runner; depends on `Unite.Data.Context` |
| `unite-identity-data-migrations` | Identity database migrations and startup runner; depends on `Unite.Identity.Data` |
| `unite-data-source-env` | Separate Data Source installation/configuration repository, intended to be checked out under installation `plugins/` |

This last repository resolves the previously unclear plugin location: the owner
uses `unite-env/plugins/unite-data-source`, while a clean local `unite-env` tree
does not contain that directory. The separate `unite-data-source-env` checkout
contains the plugin's Compose and deploy/local-build/remote-build scripts.
Its scripts read installation `.env`, `.env.local` and `.env.secrets` (through the shared `unite-env` scripts) two levels above,
matching a `plugins/<plugin>/` placement.

The reviewed plugin Compose mounts `config/`, tracking `cache/`, and host `/mnt`;
it sets Data Source's config/cache/data paths, portal host, worker host, and
worker token. These settings and mounts must match the chosen data location and
network placement. The current remote-build script does not process a branch
argument, unlike most platform application build scripts. Its exact standalone
deployment procedure and advertised resource URLs remain to be verified before
using the example configuration on a separate host.

See [SQL migrations](sql-migrations.md) and
[Deployment and development](deployment-and-development.md).

## Scientific runners and frontend visualization

The owner-confirmed method map is in
[Analysis pipeline](analysis-pipeline.md#method-and-repository-map). Only some runner
sources are currently cloned locally:

- Present: `unite-analysis-deg`, `unite-analysis-dep`, `unite-analysis-dm`,
  `unite-analysis-pcam`. Their contracts are summarized in
  [Analysis pipeline](analysis-pipeline.md#runner-contracts-local-runner-repositories).
- Not locally cloned under the owner-provided names: `unite-analysis-surv`,
  `unite-analysis-umapp`, `unite-analysis-scell`, `unite-analysis-cedp`
  (deployed by unite-env, port 5314), `unite-analysis-gaf`, and
  `unite-analysis-cnvp`. unite-env has no applications for GAF or CNVP. GAF/CNV-profile processing
  in the current Analysis checkout has internal implementations as already
  documented; owner repository descriptions and current code are distinct.
- `unite-cellxgene` is not cloned locally. The environment references its image
  and the owner explained the fork/viewer behavior.

The local `oncogrid` repository now describes **EventGrid** and publishes npm
package `@dkfz-unite/event-grid`, rather than a NuGet package or backend service.
The portal's current `Client/package.json` references it, and GAF/CNVP Vue
components import it. Those visualizations therefore have a separate repository
dependency in addition to the portal's Plotly-based views. Inspect its own
README and `docs/` when changing grids.

## Additional local repositories

These are navigation entries, not a claim that each is active in deployment:

| Repository | What the reviewed files establish | Status |
| --- | --- | --- |
| `unite-crawler` | CLI crawler and data-reader projects, depending on `Essentials.Tsv` | Current source-specific usage not yet confirmed |
| `odcf-crawler-otp` | ODCF/OTP data crawler CLI and source-format documentation | Integration/deployment details not yet reviewed |
| `unite-genome-liftover` | Web project for a future genome-reference conversion service | Owner-confirmed draft, not currently used |
| `unite-jobs` | On GitHub only `README.md` and `LICENSE`; the data/context/migration projects exist only as uncommitted local files in the owner's checkout | Owner-confirmed draft for moving the task system to a separate database |

The owner plans to move the complete task system into `unite-jobs` with a
dedicated database. Current task entities/storage and worker flows remain in
the previously documented domain-data path; the draft's migrations are not
established as part of the normal platform deployment.

`unite-genome-liftover` is intended to convert supported omics data between
GRCh37 and GRCh38 in both directions. The planned use case is separate
installations for each genome build, with users potentially wanting GRCh37
data on a GRCh38 instance or vice versa. Conversion would cover what can be
converted; support for every modality/result type is not established. The
draft does not change the current per-installation genome-build model or
provide an already available automatic conversion pipeline.

Questions about repository status can be answered as relevant components are
reviewed; they need not block navigation through the established main flow.

## CI and branches

Branch rules are in the shared [AGENTS.md](../AGENTS.md#git-workflow). The
standard is one workflow per repository, triggered on push to `main` unless
noted: service repositories use `docker-images.yml` (amd64 + arm64 under one
`:latest` manifest); library repositories use `publish-nuget.yml`. Older
single-architecture workflows were removed on 2026-10-07 in the repositories
marked *. In the repositories with `dev` the removal is on `origin/dev` and
reaches `main` with the next release merge; until then `origin/main` still has
the old `docker-image.yml` next to `docker-images.yml`.

| Repositories | `dev`? | Workflow |
| --- | --- | --- |
| `unite`*, `unite-identity`*, `unite-composer`*, `unite-analysis`*, `unite-data-source`*, `unite-ensembl-data`*, `unite-feed-donors`*, `unite-feed-images`*, `unite-feed-specimens`*, `unite-feed-omics`* | yes | `docker-images.yml` |
| `unite-analysis-deg`, `unite-analysis-dm`, `unite-analysis-pcam` | yes | `docker-images.yml`; builds unite-commands into the runner image |
| `unite-analysis-dep` | no | `docker-images.yml` |
| `unite-ensembl-vep`*, `unite-data-migrations`*, `unite-identity-data-migrations`*, `unite-commands`* | no | `docker-images.yml` (new for `unite-commands`, whose Dockerfile now follows the feed layout on the ASP.NET 8.0 runtime image) |
| `unite-data`, `unite-indices`, `unite-identity-data` | no | `publish-nuget.yml` to GitHub Packages |
| `unite-essentials`, `unite-cache` | no | `publish-nuget.yml`, also triggered on pull requests to `main` without a guard on the push step |
| `oncogrid` (fork; branches `develop`, `modern`) | no | `publish.yml`: npm package to GitHub Packages on push to `develop` |
| `unite-env`, `unite-data-source-env`, `unite-crawler`, `odcf-crawler-otp`, `unite-genome-liftover`, `unite-jobs`, `.github` | no | None |

Some service repositories have no `dev` branch (DEP runner, VEP wrapper,
commands, both migration repositories). In several repositories `main` contains
commits not merged back into `dev` (for example Identity's `NameIdentifier`
claim and the multi-arch workflows); `main` was merged into `dev` on 2026-10-07
and pushed, so `dev` now contains `main`.

## Selected source references and next step

- [Data context dependencies](https://github.com/dkfz-unite/unite-data/blob/main/Unite.Data.Context/Unite.Data.Context.csproj).
- Indices [models](https://github.com/dkfz-unite/unite-indices/blob/main/Unite.Indices/Unite.Indices.csproj), [context](https://github.com/dkfz-unite/unite-indices/blob/main/Unite.Indices.Context/Unite.Indices.Context.csproj), and [search](https://github.com/dkfz-unite/unite-indices/blob/main/Unite.Indices.Search/Unite.Indices.Search.csproj).
- [Donors Web dependencies](https://github.com/dkfz-unite/unite-feed-donors/blob/main/Unite.Donors.Feed.Web/Unite.Donors.Feed.Web.csproj) and [indexing dependencies](https://github.com/dkfz-unite/unite-feed-donors/blob/main/Unite.Donors.Indices/Unite.Donors.Indices.csproj) illustrate the feed pattern.
- [Composer dependencies](https://github.com/dkfz-unite/unite-composer/blob/main/Unite.Composer/Unite.Composer.csproj), [Analysis library](https://github.com/dkfz-unite/unite-analysis/blob/main/Unite.Analysis/Unite.Analysis.csproj), and [Analysis Web](https://github.com/dkfz-unite/unite-analysis/blob/main/Unite.Analysis.Web/Unite.Analysis.Web.csproj).
- [Mongo cache repository](https://github.com/dkfz-unite/unite-cache/blob/main/Unite.Cache/Repositories/CacheRepository.cs) and [Essentials project](https://github.com/dkfz-unite/unite-essentials/blob/main/Unite.Essentials/Unite.Essentials.csproj).
- [Data Source plugin installation](https://github.com/dkfz-unite/unite-data-source-env/blob/main/README.md) and [Compose](https://github.com/dkfz-unite/unite-data-source-env/blob/main/docker-compose.yml).
- [Portal npm dependencies](https://github.com/dkfz-unite/unite/blob/main/Unite.Web/Client/package.json), [GAF grid](https://github.com/dkfz-unite/unite/blob/main/Unite.Web/Client/src/analysis/components/gaf/EventGrid.vue), and [CNVP grid](https://github.com/dkfz-unite/unite/blob/main/Unite.Web/Client/src/analysis/components/cnvp/EventGrid.vue).

The main library/service dependencies are understood at onboarding level.
Repository entry points now connect local checkouts to the shared instructions;
see [Shared documentation setup](shared-documentation.md). The owner's usual
checks are documented in [Development validation](development-validation.md).
Missing checkouts, auxiliary repository
status, detailed per-method contracts, and planned helper extraction remain
explicitly separate from the reviewed current map.
