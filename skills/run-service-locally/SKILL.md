---
name: run-service-locally
description: Run a UNITE backend service natively instead of its Docker container to debug or test a change against the running local platform (stop the container, run on the same port, test directly or through the Vite UI, clean up, start the container again). Use when asked to run, debug or try a change in Identity, Composer, Analysis, a feed or Data Source locally.
---

# Run a UNITE service locally instead of its container

The local platform runs in Docker (unite-env). To test a backend change, replace
one container with the service running from source on the **same port**, so the
portal, the Vite dev server and the other services reach it unchanged.
Background: `unite-meta/docs/development-validation.md` ("Running a service
locally instead of its container").

## Services

| Repository | Container | Port | Run command (from the repository root) | Background workers |
| --- | --- | --- | --- | --- |
| `unite-identity` | `unite.identity` | 5000 | `dotnet run --project Unite.Identity.Web --launch-profile Unite.Identity.Web` | `RootWorker`, `AccountWorker` (deletes expired sessions and inactive accounts) |
| `unite-composer` | `unite.composer` | 5002 | `dotnet run --project Unite.Composer.Web --launch-profile Unite.Composer.Web` | none |
| `unite-analysis` | `unite.analysis` | 5004 | `dotnet run --project Unite.Analysis.Web --launch-profile http` | preparing, processing, Docker monitoring (picks up queued analyses) |
| `unite-feed-donors` | `unite.feed.donors` | 5100 | `dotnet run --project Unite.Donors.Feed.Web --launch-profile Unite.Donors.Feed.Web` | submissions, donors and projects indexing |
| `unite-feed-images` | `unite.feed.images` | 5102 | `dotnet run --project Unite.Images.Feed.Web --launch-profile Unite.Radiology.Feed.Web` | submissions, indexing |
| `unite-feed-specimens` | `unite.feed.specimens` | 5104 | `dotnet run --project Unite.Specimens.Feed.Web --launch-profile Unite.Specimens.Feed.Web` | submissions, indexing |
| `unite-feed-omics` | `unite.feed.omics` | 5106 | `dotnet run --project Unite.Omics.Feed.Web --launch-profile Unite.Omics.Feed.Web` | submissions, VEP annotation, indexing |
| `unite-data-source` | `unite.data.source` | 5400 | `dotnet run --project Unite.Data.Source.Web --launch-profile Unite.Data.Source.Web` | exploring (submits discovered files) |

The portal (`unite`, `unite.portal`, 443) is usually not replaced: frontend work
uses `npm run dev` in `unite/Unite.Web/Client` (Vite at `http://localhost:8080`,
proxying to the ports above). Verify a launch profile in the repository's
`Properties/launchSettings.json` if a command fails; profiles carry the local
environment variables.

## Steps

1. **Check the repository**: correct branch (`dev`, or a feature branch from
   it), `git status`, and the build: `dotnet build <solution>`.
2. **Check what the workers will do.** The local service starts its background
   workers against the shared local databases. Before starting a feed, check for
   pending submission, annotation or indexing tasks (they will be processed by
   your build); before starting Analysis, check for queued analyses; Identity
   runs account cleanup; Data Source submits whatever its config finds. If that
   is not wanted, tell the user before starting.
3. **Stop the container**: `docker stop <container>`.
4. **Run the service** with the command above. Wait until it listens on the
   port.
5. **Test**:
   - directly: `curl http://localhost:<port>/api/...` (most endpoints need a
     JWT; take one from the portal session or ask the user);
   - through the UI: the Vite dev server (`http://localhost:8080`) or the portal
     (`https://localhost`), which call the same port.
   UI changes need a manual check by the user in the browser.
6. **Clean up test data** you created: submissions (and their tasks), datasets,
   analyses, users or tokens. Prefer the API (e.g. the feeds' `DELETE
   api/entry/{id}`); ask before deleting anything you did not create.
7. **Stop the local service and start the container again**:
   `docker start <container>`. Never leave the platform without the service.
8. **Report** what was run, what was tested and how, what was cleaned up, and
   anything that could not be verified.

## Notes

- Shared library changes (`unite-data`, `unite-indices`, ...) can be tested by
  temporarily enabling the commented `ProjectReference` in the consumer; revert
  it before committing. See `unite-meta/docs/deployment-and-development.md`.
- Do not change the container's configuration or unite-env files to make a
  local run work; ask instead.
