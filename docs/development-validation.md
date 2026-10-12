# Code review and change validation

Last updated: 2026-10-12.

The owner explained the normal development/verification practice. This document
records that practice and how to report evidence; it does not introduce a new
mandatory test framework or claim that current code has been validated.

## Normal workflow

The owner carefully reads the code and traces the intended behavior before
running it. Then they build and run as much of the system locally as practical,
often all or almost all services, and check the affected scenario manually.

- For any change affecting the UI, run `npm run dev` from `Unite.Web/Client`
  and check the development UI at `http://localhost:8080`, including the relevant
  backend interaction. The regular portal remains at `https://localhost:443`.
  The owner mainly uses `npm run build` for Docker deployment; require a
  production build when relevant to bundling/assets or deployment verification,
  rather than as the default way to run every UI change. See
  [Frontend development](deployment-and-development.md#frontend-development-with-vite).
- For backend/API work without a UI path, exercise the relevant requests and
  responses, commonly through Postman.
- For a shared-library change, verify a consuming service, rather than only
  compiling the library in isolation. The local `ProjectReference` path and
  packaged Docker path are explained in
  [Deployment and development](deployment-and-development.md#developing-shared-libraries).
- For SQL model changes, generate/review/apply migrations locally and exercise
  affected services, following [SQL migrations](sql-migrations.md).

Choose the scenario according to the change. The owner's broad local setup
supports integrated verification; this does not mean every documentation edit
or isolated utility change requires deploying the entire platform.

## Running a service locally instead of its container

The owner's local installation runs all services in Docker. A service run
natively (from the IDE or `dotnet run`) uses the **same port** as its container,
so it replaces the container transparently. Owner's workflow, also for agents:

1. Stop the service's container: `docker stop unite.<name>` (for example
   `unite.composer`, `unite.feed.omics`, `unite.identity`; `docker ps -a` lists
   them with their ports).
2. Run the service natively on its own URL and port, using its launch profile
   (`dotnet run --project <Web project> --launch-profile <Web project>`). The
   profile points to the local databases and services.
3. Test it directly, or through the portal UI. For the UI, use the Vite dev
   server at `http://localhost:8080` (`npm run dev` in
   `unite/Unite.Web/Client`): it proxies the same services as the portal in
   Docker, to the same localhost ports, so it reaches the native service
   automatically.
4. When done, stop the native service and start the container again:
   `docker start unite.<name>`.

Precautions:

- A natively run service starts its background workers too (submission,
  annotation, indexing, analysis). They process any pending tasks in the local
  database. Check for pending tasks before starting it.
- Test requests that are accepted write real data to the local databases (staged
  submissions in Mongo, SQL tasks, records). Use recognizable test identifiers and
  remove the test data afterwards; report what was created and removed.
- Tell the owner which container was stopped, and make sure it is started again
  even when the test fails.

## Focused unit tests

The owner writes unit tests for specific logic that benefits from them, such
as computations, custom attributes, and similarly unusual behavior. Such tests
have often been temporary and removed by the owner after checking correctness.

The owner does not consider exhaustive method-by-method tests with mocks for
every dependent service useful. Do not add this style of test merely to increase
coverage or mirror the implementation. Prefer focused checks that establish a
meaningful property, edge case, or regression.

This explanation is not an instruction to delete existing tests or rewrite CI.
Preserve existing work and run checks relevant to the affected component.
Where a new test is useful, consider whether retaining it would help catch a
real regression; distinguish that decision from a temporary local diagnostic.

## Agent validation and reporting

Use code inspection to select the right checks, then report what was actually
done. Tracing a path mentally, compiling it, sending an API request, and testing
the portal supply different evidence.

- State which build/check was run and which behavior was exercised.
- Describe failures or unavailable prerequisites specifically. If an intended
  manual/integration check could not be run, leave it explicitly unverified.
- A successful build alone does not prove UI, authorization, data preservation,
  asynchronous processing, or analysis-file contracts correct.
- For documentation-only work, check changed Markdown, navigation targets, and
  consistency with the inspected source/owner explanation. Do not claim service
  tests were run when only documentation checks were performed.

Shared-contract changes require checking the relevant consumers identified in
[Repository map](repository-map.md). Scope verification to the change and
unresolved concerns rather than repeating unrelated checks after they pass.

## Next onboarding step

The main architecture, package relationships, installation, migration workflow,
and validation practice are documented. Repository-level agent entry points now
connect local checkouts to the shared instructions; see
[Shared documentation setup](shared-documentation.md). Component-specific formats, algorithms,
access-control questions, and operational procedures can be refined as those
components are changed.
