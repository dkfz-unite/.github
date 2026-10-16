# Deployment and local development

Last updated: 2026-10-12.

The owner explained installation and deployment during onboarding. Selected
local `unite-env` scripts and Compose files confirm the main workflow. This is
a navigation guide, not evidence that an installation was run or validated.

## Role of unite-env and its two checkouts

`unite-env` contains installation configuration and scripts for the platform.
The same process is used locally and on servers. The owner keeps two checkouts:

- A development checkout alongside the source repositories for editing scripts
  and configuration.
- An installation checkout from which the actual Docker deployment is managed.

Determine which checkout is relevant before changing configuration or running
commands. Paths below are relative to the selected installation checkout;
developer-specific absolute paths do not belong in shared instructions.

The scripts are invoked through `sh`; executable permissions are not required.
Run them **from their containing directory** because they use relative paths
to Compose files, configuration, credentials, and other scripts.

## Repository structure and configuration

| Location | Responsibility |
| --- | --- |
| `programs/` | PostgreSQL, MongoDB, Elasticsearch, and legacy MySQL for Ensembl; optional database/search management UIs |
| `applications/` | Portal, Identity, Composer, Analysis, feeds, Ensembl wrappers, scientific runners, and SQL migration applications |
| `plugins/` (owner's installation checkout) | Optional plugins; gitignored, so absent from a clean clone. Data Source configuration comes from the separate `unite-data-source-env`, cloned here |
| `scripts/` | Whole-installation configuration, deployment/build orchestration, certificates, and optional management-tool deployment |
| `.env` | Shared configuration in the repository: instance settings, hosts and ports of PostgreSQL, MySQL, MongoDB and Elasticsearch |
| `.env.secrets` | Installation credentials, created from `.env.secrets.template`; gitignored |
| `ssl/` | Portal certificate/key mounted into the portal container |

Runtime settings live in each component's `docker-compose.yml`, which maps
the variables it needs explicitly from the shared env files, e.g.
`UNITE_SQL_HOST: ${UNITE_PGSQL_HOST}` or `UNITE_SQL_USER: ${UNITE_PGSQL_USER}`.
Every script passes both files:
`docker compose -p unite --env-file ../../.env --env-file ../../.env.secrets ...`.
Scripts that need a secret themselves (the GitHub token for `git clone`, the
MySQL and Elasticsearch helper scripts) load it with
`. ../../.env.secrets` (shell variables only, not exported). Build-specific
`docker-compose.build.yml` files contain only the build context and local image
name; the build scripts merge them with the base file
(`-f docker-compose.yml -f docker-compose.build.yml`).

Fixed user names: MySQL's user is always `root` (the image only sets the root
password) and Elasticsearch's is always `elastic` (the built-in superuser);
Kibana connects as the built-in `kibana_system` user with the same password,
set by `programs/elasticsearch/deploy.mgmt.sh`. Compose prefers shell variables
over env files, so compose files use `UNITE_*` names only (never `USER` or
`PASSWORD`, which the shell defines).

Each application's `deploy.sh`, `build.remote.sh` and `build.local.sh` is a
one-line call of the shared scripts in `scripts/app/` with a service key
(`sh ../../scripts/app/build.remote.sh composer "$1"`). Display name, local
path, repository URL and optional default branch of each service are in
`.env.services`; `.env.services.local` (gitignored) overrides single services,
e.g. to build from a fork, another folder or a branch. The GitHub token is sent
to `github.com` as an HTTP header, not as part of the clone URL. Plugins use
the Compose project `unite-plugins`.

This is on branch `compose` in `unite-env` and `unite-data-source-env`
(2026-10-12), replacing `secrets.json` read with `jq` and service-level
`extends`. Moving secrets to Docker secrets is planned.

## Initial installation

The owner can run the complete platform locally by cloning `unite-env` and
following its [installation README](https://github.com/dkfz-unite/unite-env/blob/main/README.md).
The documented sequence is:

1. Create `.env.secrets` from `.env.secrets.template` and review `.env`. The
   owner normally keeps development defaults locally; actual credentials must
   not be copied into shared onboarding. For local builds, set
   `UNITE_SOURCE_PATH_PREFIX` once in the shell profile to the folder with the source
   repositories; `build.local.sh` stops with a message if it is missing.
2. From `scripts/`, run the platform-specific configuration script,
   `sh configure.macos.sh` or `sh configure.linux.sh`. Both create Docker network
   `unite`; the Linux script also configures `vm.max_map_count` and network MTU.
3. Provide a certificate/key in `ssl/` or use `sh generate-ssl.sh` from
   `scripts/` for a development certificate, following the README.
4. Choose the installation's genome build in `UNITE_GENOME_BUILD` in `.env`
   (`GRCh37`, the default, or `GRCh38`). Compose passes it to the omics feed
   and Composer, and the Ensembl cache scripts download the reference data of
   that build. Reference-data compatibility is installation-specific; do not
   treat it as a per-request switch.
5. From `scripts/`, run `sh deploy.sh` to deploy programs and applications.
6. Optionally run `sh deploy.mgmt.sh` from `scripts/` for management UIs.
7. Separately download/extract/import Ensembl data and download/extract VEP
   cache files as described below.

The current top-level deploy script starts PostgreSQL, MySQL, MongoDB, and
Elasticsearch, invokes domain and identity migration applications, and then
deploys platform services, Ensembl wrappers, and configured scientific runners.
Its sequential shell calls do not establish that every component is healthy
or that detached migration applications have completed; see
[SQL migrations](sql-migrations.md) for startup behavior and local development.

## Deployment and build modes

The owner deploys on a server over SSH (owner-confirmed 2026-10-07):

- Full update: `sh unite-env/scripts/deploy.sh` updates everything.
- Specific components: go to `unite-env/applications/<component>/` and run
  `sh deploy.sh` (published image), or `sh build.remote.sh <branch>` to build an
  image from a branch (default `main`).

Run the following commands inside `applications/<service>/`:

| Command | Source and resulting behavior |
| --- | --- |
| `sh deploy.sh` | Pull the published GHCR image and start/update the service |
| `sh build.remote.sh` | Clone remote source, normally `main`, build an image locally, and start/update the service |
| `sh build.remote.sh dev` | Clone the selected branch where the script supports a branch argument, build locally, and start/update the service |
| `sh build.local.sh` | Copy the local repository's contents from `$UNITE_SOURCE_PATH_PREFIX`, build locally, and start/update the service |

The filename is `build.remote.sh`, not `build.remove.sh`. The scripts are not
build-only operations: they also run `docker compose ... up -d --build`.

Application deployment files reviewed here use
`ghcr.io/dkfz-unite/<repository>:latest` with `pull_policy: always`. The owner
confirmed that pushes to `main` build amd64 and arm64 images and push them to
GHCR. A published image deployment differs from building a selected source
branch.

Every service repository has one image workflow, `docker-images.yml`: it
builds amd64 and arm64 images and combines them under one `:latest` manifest.
Library repositories instead build and push NuGet packages. Older
single-architecture workflows were removed on 2026-10-07 (pushed; in
repositories with `dev` they leave `main` with the next release). See
[Repository map](repository-map.md#ci-and-branches).

The portal `Dockerfile` on `main` needs build argument `GITHUB_TOKEN` to install
`@dkfz-unite/event-grid` from GitHub Packages. `docker-images.yml` and
`build.remote.sh` pass it; `build.local.sh` does not.

Remote/local build scripts replace the component's installation-side `src/`
directory before cloning/copying source into it. The development source checkout
is separate. Local copying includes working-tree files, so it can incorporate
uncommitted edits. This does not automatically substitute edited sibling
libraries for package dependencies; see the shared-library workflow below.

Most remote-build scripts reviewed accept a branch argument with `main` as
the default. The current identity-data-migrations script is an exception: it
clones without processing a branch argument. Inspect the selected component
rather than assuming every script has an identical contract.

For a complete deployment/update, the owner's usual command is
`sh deploy.sh` from `scripts/`. That script covers four programs, both
migrations, portal, Identity, Composer, Analysis, the four feeds, both Ensembl
wrappers and the runners DEG, Scell, Surv, DM, PCAM, DEP, UMAPP and CEDP. It does
not include Data Source and has no health waits.

`scripts/` also contains destructive helpers: `uninstall.soft.sh` removes
**all containers on the host** (`docker rm -f $(docker container ls -aq)`), not
only UNITE's; `uninstall.hard.sh` also removes all images and volumes;
`clean.sh` removes UNITE containers/images, the Elasticsearch, MongoDB and
analysis-data volumes, and drops the `unite_data` database. Never run them on a shared host without the owner.

Infrastructure images are partly unpinned: `postgres` (no tag), `mongo:latest`
and `mongo-express:latest`; Elasticsearch and Kibana are pinned to 7.17.7.
`sh deploy.apps.sh` has a smaller explicit list: migrations, portal, Identity,
Composer, Analysis, and feeds; it does not update every runner or Ensembl wrapper.
`sh build.sh` builds remote application sources and deploys programs;
`sh build.apps.sh` uses the smaller application list. These top-level build
scripts currently do not forward a branch argument to child scripts.

## Frontend development with Vite

The owner develops the frontend through Vite while the regular portal service
and backend services remain running. From `unite/Unite.Web/Client/`, run:

```sh
npm run dev
```

The configured dev address is `http://localhost:8080`. The regular `unite`
portal service remains at `https://localhost:443`. These are separate processes:
Vite serves the development UI; the ASP.NET portal serves its built `Client/dist`
and its server endpoints.

The reviewed `vite.config.js` supplies development proxy routes:

| Route | Local target |
| --- | --- |
| `/api/config` | Portal at `https://localhost:443` |
| `/api/identity`, `/api/composer`, `/api/analysis` | Respective services directly on loopback ports 5000, 5002, 5004, rewriting the prefix to `/api` |
| `/api/feed-donors`, `/api/feed-images`, `/api/feed-specimens`, `/api/feed-omics` | Respective feeds directly on loopback ports 5100, 5102, 5104, 5106, rewriting the prefix to `/api` |
| `/viewer/cxg<n>` | Loopback viewer port `54300 + n` selected by the development proxy |

Thus the development UI still needs its relevant services running; Vite does
not provide their APIs. The portal's production reverse proxy and Vite's dev
proxy have separate configurations. Consult the
[Vite config](https://github.com/dkfz-unite/unite/blob/main/Unite.Web/Client/vite.config.js)
when changing local routes.

The owner mainly uses `npm run build` for Docker deployment. The portal
[Dockerfile](https://github.com/dkfz-unite/unite/blob/main/Dockerfile) runs that
command in its client build stage and copies the generated `dist/` into the
runtime image. Routine UI iteration/manual verification uses `npm run dev`;
a production build is an additional relevant check when the change affects
bundling/assets or when preparing deployment, rather than the default way to
run the development UI.

## Developing shared libraries

The owner confirmed two ways of consuming library changes:

- **Local development:** temporarily use a `ProjectReference` pointing into the
  sibling source repository. These references are often already present but
  commented out in service project files. Composer's
  `Unite.Composer/Unite.Composer.csproj` contains examples for
  `unite-data/Unite.Data.Context` and `unite-indices/Unite.Indices.Search`.
- **Docker verification:** push library changes to `main`, where GitHub Actions
  builds and publishes new NuGet packages. Use the new package version in the
  consuming service and build/deploy that service for verification. Merely
  copying its local source does not include sibling library repositories in
  its Docker build context.

Library versions follow `major.minor.patch` (owner-confirmed 2026-10-08):

- **Patch** (third number): increased for every package published during
  development, e.g. to test a change in a consumer's Docker build.
- **Minor** (second number): increased when the change is finished and released.
- **Major** (first number): increased for breaking changes, for example a new
  .NET version or a data structure that changed so much that compatibility with
  existing data cannot be guaranteed.

The reviewed `unite-data` and `unite-indices` publication workflows run on pushes
to `main`, restore/build/test, pack their library projects, and push packages
to the organization's GitHub Packages NuGet source. Versions come from library
project files. Service project files use explicit `PackageReference` versions,
so publication alone does not update their dependencies. The shared-library
source/package path and its consumers must be considered together when checking
a change. Local source references and packaged Docker builds can otherwise
exercise different code versions.

## Ensembl database and VEP cache

Deploying the containers does not populate their reference data automatically.
The owner performs these additional setup steps separately:

- From `programs/mysql/`, run `sh download-cache.sh`, `sh extract-cache.sh`,
  and `sh install-cache.sh`. Download selects required Ensembl core tables;
  install imports schema/data into the local MySQL server
  (`homo_sapiens_core_116_37` or `homo_sapiens_core_116_38`). Both builds have
  the same core schema and tables in release 116. Compose currently pins `mysql:5.6` on
  `linux/amd64` and mounts `cache/` separately from the database data volume.
- From `applications/unite-ensembl-vep/`, run `sh download-cache.sh` and
  `sh extract-cache.sh`. They download the indexed VEP cache, the only cache
  type published since release 114. The local `data/` directory is mounted as
  container `/cache`.

The scripts read the genome build from `.env` through `scripts/ensembl.sh`,
which also fixes Ensembl release 116. Release 116 is the last release published
on `ftp.ensembl.org` with MySQL dumps and VEP caches; newer Ensembl data is
published only on the new Ensembl platform (`ftp.ebi.ac.uk/pub/ensemblorganisms/`)
as gene annotation, sequence and variation files. The release is therefore
hardcoded in the scripts and in Ensembl Data, and the VEP image is pinned to
`release_116.3`; the VEP image and cache releases must match. Reference
downloads/extraction persist on disk across normal service deployments.

## Local versus server access

The owner manages servers through SSH, without a desktop UI. The portal is
reachable in a browser; the owner's server setup exposes HTTP/HTTPS on ports
80/443 for web access. Database/service ports are not directly reachable from
the developer's computer, so local tools do not normally connect directly to
server databases. The same deployment scripts run on the server.

Reviewed core Compose files publish database and internal API ports on the
server's `127.0.0.1`; the portal publishes 80/443 without that restriction.
Docker services communicate on network `unite` using service aliases such as
`pgsql.unite.net` and `identity.unite.net`.

Management tools (Adminer, Mongo Express, Kibana on host ports 8081–8083) are
optional and deployed through `deploy.mgmt.sh`. Check their port bindings
before deploying them on a server.

### Data Source placement

Data Source can be installed alongside the portal or separately near the data.
The owner's servers currently run it on the portal server and mount directories
from data servers on their local network. Separate placement can reduce
filesystem access latency; UNITE receives metadata/integrated values through
feed APIs and retrieves hosted resource files over HTTP for analysis.

The owner identified `plugins/unite-data-source` in the installation's
`unite-env` repository. That folder is absent from the current local checkout,
and a separate local `unite-data-source-env` repository provides the plugin
Compose/deploy/build configuration. Selected scripts and mounts are reviewed
in the [Repository map](repository-map.md#installation-and-migrations); their
inclusion in top-level orchestration has not been established. Do not infer
that the reviewed `scripts/deploy.sh` starts Data Source. Its responsibility is described in
[Data ingestion](data-ingestion.md#deployment-and-data-access).

## Code navigation and next discussion

- [Whole-platform deploy](https://github.com/dkfz-unite/unite-env/blob/main/scripts/deploy.sh) and [smaller application update](https://github.com/dkfz-unite/unite-env/blob/main/scripts/deploy.apps.sh).
- Composer's [deploy](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-composer/deploy.sh), [remote build](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-composer/build.remote.sh), [local build](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-composer/build.local.sh), and [build override](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-composer/docker-compose.build.yml) illustrate the main pattern.
- [Identity deployment](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-identity/deploy.sh) and [configuration](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-identity/docker-compose.yml) illustrate the initial `.env` migration.
- Composer's [Docker publication workflow](https://github.com/dkfz-unite/unite-composer/blob/main/.github/workflows/docker-images.yml).
- Composer's [package and commented local-project references](https://github.com/dkfz-unite/unite-composer/blob/main/Unite.Composer/Unite.Composer.csproj).
- [unite-data NuGet publication](https://github.com/dkfz-unite/unite-data/blob/main/.github/workflows/publish-nuget.yml) and [unite-indices NuGet publication](https://github.com/dkfz-unite/unite-indices/blob/main/.github/workflows/publish-nuget.yml).
- [MySQL installation](https://github.com/dkfz-unite/unite-env/blob/main/programs/mysql/README.md) and [VEP cache download](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-ensembl-vep/download-cache.sh).

The main installation/deployment and shared-library development workflows are
understood. The model/mapping split and SQL migration workflow are covered in
[SQL migrations](sql-migrations.md). The initial [Repository map](repository-map.md)
now covers packages, consumers, and plugin configuration. Shared-agent entry
points are described in [Shared documentation setup](shared-documentation.md).
The owner's normal checks are documented in
[Development validation](development-validation.md). Migration completion checks, exact service-update
timing, backup/restore procedures, and detailed operational
validation are not yet documented. Planned `.env`/Compose refactoring belongs
to a separate implementation task.
