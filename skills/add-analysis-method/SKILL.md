---
name: add-analysis-method
description: Add a new downstream analysis method to UNITE (or rework an existing one) end to end - agree inputs, outputs and visualization with the owner, register the task type, implement Prepare/Process in unite-analysis, create the runner repository around unite-commands, deploy it in unite-env, and add the portal dialog and result views. Use when asked to add, port or restructure an analysis method.
---

# Add an analysis method

Analyses run on saved datasets in two phases: **Prepare** (select samples
through search with the user's scope, load data, write inputs) and **Process**
(run the method internally or in a runner container, postprocess, archive).
Read first:

- `unite-meta/docs/analysis-pipeline.md`, especially "Intended structure for
  analyses" (folder layout, rules, sample identifiers, archiving) and the
  runner contracts;
- `unite-analysis/AGENTS.md` ("Adding or changing an analysis method");
- the most recent method as the reference, currently **CEDP**, not older ones.

Methods are not uniform yet. The goal is one template with a ready input API,
so build new methods to the intended structure and do not copy older
deviations.

## Phase 1: agree the method with the owner

Ask one question at a time and record the answers in the analysis pipeline
document:

1. Purpose, name and short key (e.g. `cedp`), and who writes the scientific
   script (owner or bioinformatician).
2. **Eligibility**: number of datasets and which data they must have (the
   availability flags the portal checks, e.g. `exp`, `prot`, `meth`).
3. **Inputs**: which data and metadata (`samples.tsv`, `data.tsv`/`.json`,
   `metadata.tsv`, annotations, downloaded resources in `samples/`),
   `options.json` and its options.
4. **Runner or internal**: external R/Python runner (most methods) or internal
   processing (like GAF and CNV profiles); language, packages, memory and CPU,
   expected run time, process limit.
5. **Outputs**: result files in `output/`, the file the portal loads, the
   visualization (Plotly, event grid with samples, regions and observations,
   Cell-x-Gene), and what goes into the downloadable archive.
6. Sample identifiers: use the names settled for the template; if still open,
   ask (see "Sample identifiers" in the analysis pipeline document).

Check Jira ("Improvements and Ideas" and "Known Issues", component analysis)
for related directions and defects.

## Phase 2: implement

| Step | Repository | What |
| --- | --- | --- |
| 1 | `unite-data` | Add the value to `AnalysisTaskType` (`Entities/Tasks/Enums`); publish (skill `publish-library`) |
| 2 | `unite-data-migrations` | Migration for the new task type value (see e.g. `CnvProfileAnalysisTaskType`) |
| 3 | `unite-analysis` | `Unite.Analysis/Services/<Method>/`: `AnalysisService` with `Prepare`/`Process`, loaders and writers, `Load`/`Download`/`Delete`, `DefaultLoadFileName`; request model and options; endpoint in `AnalysisController`; branches in the preparing and processing handlers, load/download/delete and `AnalysesController` delete-all; runner host option `UNITE_ANALYSIS_<METHOD>_HOST` in `AnalysisOptions`; `Docs/api-analysis-<method>.md` and the API index |
| 4 | `unite-analysis-<method>` (new) | Runner: `src/install` (`install.R` or equivalent), `src/run` (entry script reading `input/`, writing `output/`), `Dockerfile` based on an existing runner (`UNITE_COMMAND`, `UNITE_COMMAND_ARGUMENTS`, `UNITE_PROCESS_LIMIT`, `/mnt/data`), `docker-images.yml` building unite-commands into the image (do not commit binaries), `README.md` with the file contract, `AGENTS.md`/`CLAUDE.md` from the templates |
| 5 | `unite-env` | `applications/unite-analysis-<method>/` (compose with `unite.analysis.data` volume, next free `127.0.0.1:53xx` port, deploy and build scripts), the host variable in the analysis service compose |
| 6 | `unite` | `analysis/components/<method>/`: `analysis.ts`, `options.ts`, `Dialog.vue` (`canShow` eligibility), `Viewer.vue`, `Results.vue`; register in `_shared/analysis-type.ts`, `_shared/analysis-factory.ts`, `AnalysisButton.vue`, `analysis/Page.vue`; reuse shared grid or Plotly components |

Rules from the intended structure:

- inputs in `input/`, results in `output/`, downloaded resources in `samples/`;
- the user scope comes from the token (personal criteria), never from the
  request;
- a busy runner (HTTP 501) means "try again later": do not delete inputs or
  archive before processing and postprocessing succeeded;
- failures need a manual restart by the user; write the failure reason where
  the user can see it;
- remove large downloaded resources after success, then archive.

Work on feature branches from `dev` (a new runner repository gets `main` and
`dev`). Commit per repository; the owner pushes, creates the repository and
deploys.

## Phase 3: verify

- Build `unite-analysis` and the portal; build the runner image locally.
- Run the runner container and the analysis service locally (skill
  `run-service-locally`), start the analysis from the portal on a small
  dataset, check eligibility, preparation files, processing, the busy-runner
  retry (process limit 1, two analyses), the results view, the download and
  deletion (files removed).
- Report what was verified and what needs the owner's manual check.

## Notes

- Grid-like results use samples, regions and observations, like the CNV
  profiles grid (Jira improvements epic).
- Add new findings about the template to the analysis pipeline document.
