---
name: publish-library
description: Prepare a new version of a UNITE shared NuGet library (unite-data, unite-indices, unite-identity-data, unite-cache, unite-essentials) and update its consumers - test the change locally through project references, bump the version by the team's rules, and list or update the consumers that pin the package. Use when a change in a shared library has to reach a service, or when asked to publish, release or bump a library version.
---

# Publish a shared library version

UNITE's shared libraries are NuGet packages published to GitHub Packages.
Consumers pin explicit versions, so a library change reaches a service only
after a new package is published **and** the service's `PackageReference` is
updated. Background: `unite-meta/docs/deployment-and-development.md`
("Developing shared libraries") and `unite-meta/docs/repository-map.md`
("Package versions per consumer").

## Libraries

| Repository | Packages (`.csproj` with `<Version>`) | Target |
| --- | --- | --- |
| `unite-data` | `Unite.Data`, `Unite.Data.Context` | .NET 8 |
| `unite-indices` | `Unite.Indices`, `Unite.Indices.Context`, `Unite.Indices.Search` | .NET 8 |
| `unite-identity-data` | `Unite.Identity.Data` | .NET 8 |
| `unite-cache` | `Unite.Cache` | .NET 6 |
| `unite-essentials` | `Unite.Essentials` | .NET 8 |

`Unite.Essentials.Tsv` (`unite-essentials-tsv`) is also used by most services
but is not checked out in the workspace; ask before changing it.

Packages of one repository share one version: bump all of its `.csproj` files
together. Library repositories have no `dev` branch; work on `main`.

## Versioning (owner's rules)

`major.minor.patch`:

- **patch**: every package published during development, e.g. to try a change
  in a consumer's Docker build;
- **minor**: when the change is finished and released;
- **major**: breaking changes, e.g. a new .NET version or a data structure that
  changed so much that compatibility with existing data cannot be guaranteed.

The publish workflow pushes with `--skip-duplicate`: a push to `main` without a
version bump publishes **nothing** and does not fail. Always bump.

## Steps

1. **Check the repository**: on `main`, `git status` clean apart from the
   change, `origin/main` fetched. Read the repository's `AGENTS.md`.
2. **Find the consumers** of the changed package: the version table in
   `repository-map.md`, then confirm with a search of `PackageReference` in
   the workspace (e.g. `grep -rn 'Include="Unite.Data.Context"' --include=*.csproj`).
   Note which consumers actually use the changed code.
3. **Test locally before publishing**: in a consumer, temporarily switch the
   `PackageReference` to the commented `ProjectReference` pointing into the
   sibling library repository, build and exercise the scenario (see the
   `run-service-locally` skill). Revert this before committing the consumer.
4. **For schema changes** in `unite-data` or `unite-identity-data`, the
   migration goes to the matching migrations repository; follow
   `unite-meta/docs/sql-migrations.md`.
5. **Bump the version** in every `.csproj` of the library repository by the
   rules above. Build the library (`dotnet build <solution>`) and run its tests
   if there are any (`unite-essentials` has a test project).
6. **Commit** the change and the bump on `main` with a message naming the new
   version. Do not push: the owner pushes, and the push to `main` runs
   `publish-nuget.yml`, which publishes the packages.
7. **Update consumers after publication** (when the owner confirms the
   package is available): set the new version in each consumer's
   `PackageReference` on its `dev` branch (or `main` for repositories without
   `dev`), `dotnet restore` and build, run the affected scenario, commit. NuGet
   restore needs the GitHub Packages source with credentials in the developer's
   NuGet configuration.
8. **Update the docs**: the version table in `repository-map.md` and the
   "Shared libraries" section of each updated consumer's `AGENTS.md`.
9. **Report** the new version, the consumers updated and those deliberately
   left on older versions, and what was tested.

## Notes

- Do not update consumers that do not need the change unless asked; version
  skew is normal, but note it.
- Index model changes (`unite-indices`) require reindexing after deployment;
  say so in the report.
- Changing claims, criteria or document shapes is a cross-service change:
  check every consumer, not only the one that motivated the change.
