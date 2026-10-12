# SQL models, mapping, and migrations

Last updated: 2026-10-07.

The owner explained the code-first model and migration development workflow.
Selected local contexts, factories, migration applications, and deployment
files confirm the implementation details below. No database commands were run
during this documentation work.

## Separate databases and migration repositories

| Model repository | PostgreSQL database | Migration repository and executable project |
| --- | --- | --- |
| `unite-data` | `unite_data` | `unite-data-migrations` / `Unite.Data.Migrations` |
| `unite-identity-data` | `unite_identity` | `unite-identity-data-migrations` / `Unite.Identity.Data.Migrations` |

These are separate databases even though the current installation connects
both migration applications to `pgsql.unite.net`. Biomedical-domain models and
identity models have separate migration histories and model snapshots.
This workflow concerns the EF/PostgreSQL schemas; it does not establish a
migration procedure for MongoDB, Elasticsearch, or Ensembl reference data.

## Entity definitions and explicit database mapping

The owner uses **code first** with explicit Fluent API mapping classes rather
than relying on conventions for the complete mapping. In current code the
mappers configure tables, keys, relationships, conversions and required fields,
while domain column names are declared with `[Column("...")]` attributes on
entity properties. Identity entities have no column attributes and no
`HasColumnName`, so identity columns use EF naming conventions (PascalCase).

`unite-data` contains two library projects:

- `Unite.Data`: plain biomedical entity definitions, enums, and relationships.
- `Unite.Data.Context`: `DomainDbContext`, PostgreSQL configuration, mapping
  classes under `Mappers/`, `Repositories/` with related-entity lookup helpers,
  and `Services/` (data writer, stats, tasks). It references `Unite.Data`.

Mapping classes implement `IEntityTypeConfiguration<T>` and configure tables,
keys, properties, relationships, and other database details. The context applies
these configurations in `OnModelCreating`. Read both the entity and its mapper
when changing how data is stored; migrations are generated from the resulting
EF model.

Identity follows the same conceptual separation. In the current local checkout,
however, **one project**, `Unite.Identity.Data`, contains `Entities/`,
`Services/IdentityDbContext.cs`, and `Services/Mappers/`. Do not assume a separate
`Unite.Identity.Data.Context` project exists. This is a layout difference, not a
different migration development workflow.

Both contexts explicitly configure their respective migration assembly.
Migration classes and the EF model snapshot live in the separate migration
repositories, rather than alongside the model libraries.

## Preparing the model dependency

After changing domain entities/mappers, make the new model available to the
corresponding migration project through either of the owner's usual paths:

- Temporarily enable a sibling `ProjectReference`. Both migration project files
  already contain commented examples pointing to their model repository.
- Publish the model library with a new patch version through a push to `main`,
  then update the migration project's package reference to that version.

`Unite.Data.Migrations` references `Unite.Data.Context`;
`Unite.Identity.Data.Migrations` references `Unite.Identity.Data`. Check the
selected dependency before generating a migration. The migration project and
application services can otherwise use different model versions. For example,
on 2026-10-07 domain migrations pin `Unite.Data.Context` 12.10.20 while the
library is at 12.10.33; the entities and mappers have not changed since 12.10.20,
so the schema is equivalent. Identity migrations and library are both at 4.3.0.

Latest migrations (2026-10-07): domain `20260812084253_DataUserProject`
(project users and `IsPublic`), identity `20261005091108_Activity` (activity
tracking, password-reset fields, session ID).

The owner prefers to settle the model design before generating migrations:
consider what is needed, existing data, and how services will use the change.
Repeated regeneration has been rare and is a local development fallback.
See [Deployment and development](deployment-and-development.md#developing-shared-libraries)
for the shared-library publication and verification workflow.

## Generate, review, and test locally

Run EF commands from the executable migration project directory:
`unite-data-migrations/Unite.Data.Migrations/` or
`unite-identity-data-migrations/Unite.Identity.Data.Migrations/`.
Both have an `IDesignTimeDbContextFactory` using their SQL options. Configure
the local target through `UNITE_SQL_HOST`, `UNITE_SQL_PORT`, `UNITE_SQL_USER`, and
`UNITE_SQL_PASSWORD`; when unset, the factories fall back to a local PostgreSQL
on `localhost:5432` with built-in development defaults. Actual credentials do
not belong in documentation.
The reviewed projects target .NET 8 and use EF Design 8.0.11.

1. Generate a migration with `dotnet ef migrations add <name>`. Prefer a short,
   single-word name where practical.
2. Inspect the generated `Up()` and `Down()` methods. Edit the migration when
   the generated operations do not express the intended transformation. In
   particular, preserve/update existing data when that is the requirement,
   rather than accepting destructive replacement operations automatically.
3. Apply it to the local database with `dotnet ef database update`.
4. Start the affected services and check their behavior against the updated
   database. The owner uses this to verify the change before publication.
5. If satisfactory, push the migration repository. Publication and deployment
   follow the normal image workflow.

This review of generated operations is part of the normal process, even when
generation succeeds. A schema change's correctness also depends on existing
data and application behavior.

## Revising the last unpublished local migration

If local verification shows that the model/migration needs revision, the owner
rolls the local database back to the previous migration, removes the last
migration, adjusts the model/dependency, then generates and tests again:

```sh
dotnet ef database update <previous-migration>
dotnet ef migrations remove
```

The rollback command is **database update**, not `migrations update`. The target
names the state to restore; EF uses `Down()` for migrations newer than that
target. `migrations remove` then removes the latest migration from the project.
Command syntax is documented in the official
[EF Core CLI reference](https://learn.microsoft.com/en-us/ef/core/cli/dotnet).

This records a local development loop before the migration is published/shared.
It is not a procedure for rewriting migration history already deployed to other
installations. Shared migration correction and production rollback procedures
have not yet been discussed.

## Applying migrations in Docker

Both migration repositories build dedicated console application containers.
Their entry points create the relevant context and call
`dbContext.Database.Migrate()`, then finish. They do not expose a web API or act
as continuous migration workers. Each invocation applies pending migrations
known to the deployed migration assembly.

The owner confirmed that servers run these containers during deployment so the
databases normally stay up to date. Both `unite-env/scripts/deploy.sh` and
`deploy.apps.sh` invoke the domain and identity migration deployment scripts
before the main application deployments. The component Compose files use
published `latest` images with `pull_policy: always` and the shared PostgreSQL
host credentials.

Source ordering and successful migration completion are distinct. The reviewed
scripts use detached `docker compose ... up -d --build` without an explicit
wait for migration completion. The console entry points catch migration
exceptions and print failure messages without rethrowing or explicitly setting
a failing exit code. Therefore a finished container or continuing deployment
script alone does not prove successful migration. Completion/error handling and
the owner's detailed service-update sequence remain operational review topics;
no startup or deployment behavior was changed here.

## Code navigation and remaining questions

- [Domain context](https://github.com/dkfz-unite/unite-data/blob/main/Unite.Data.Context/DomainDbContext.cs) and [example donor mapper](https://github.com/dkfz-unite/unite-data/blob/main/Unite.Data.Context/Mappers/Donors/DonorMapper.cs).
- [Identity context](https://github.com/dkfz-unite/unite-identity-data/blob/main/Unite.Identity.Data/Services/IdentityDbContext.cs) and [example user mapper](https://github.com/dkfz-unite/unite-identity-data/blob/main/Unite.Identity.Data/Services/Mappers/UserMapper.cs).
- Domain migration [project/dependency](https://github.com/dkfz-unite/unite-data-migrations/blob/main/Unite.Data.Migrations/Unite.Data.Migrations.csproj), [design-time factory](https://github.com/dkfz-unite/unite-data-migrations/blob/main/Unite.Data.Migrations/DomainDbContextFactory.cs), [entry point](https://github.com/dkfz-unite/unite-data-migrations/blob/main/Unite.Data.Migrations/Program.cs), and [snapshot](https://github.com/dkfz-unite/unite-data-migrations/blob/main/Unite.Data.Migrations/Migrations/DomainDbContextModelSnapshot.cs).
- Identity migration [project/dependency](https://github.com/dkfz-unite/unite-identity-data-migrations/blob/main/Unite.Identity.Data.Migrations/Unite.Identity.Data.Migrations.csproj), [design-time factory](https://github.com/dkfz-unite/unite-identity-data-migrations/blob/main/Unite.Identity.Data.Migrations/IdentityDbContextFactory.cs), [entry point](https://github.com/dkfz-unite/unite-identity-data-migrations/blob/main/Unite.Identity.Data.Migrations/Program.cs), and [snapshot](https://github.com/dkfz-unite/unite-identity-data-migrations/blob/main/Unite.Identity.Data.Migrations/Migrations/IdentityDbContextModelSnapshot.cs).
- [Domain migration deployment](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-data-migrations/deploy.sh) and [identity migration deployment](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-identity-data-migrations/deploy.sh).

The model/mapping split and main migration development/application workflow are
understood. Remaining operational details include exact service-update timing,
backup/restore and production rollback, and verification of migration success.
Continue the repository/deployment map and shared-agent instruction entry points;
these open details need not block the general onboarding.
