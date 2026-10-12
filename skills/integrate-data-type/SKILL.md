---
name: integrate-data-type
description: Plan and implement the integration of a new data type (modality, result kind, sample or file type) into UNITE end to end - settle the questions with the owner, write the decisions down, produce a per-repository change plan, and implement it in dependency order (model, migration, feed, indexing, search, API, Data Source, portal, analyses). Use when asked to add or integrate a new kind of data.
---

# Integrate a new data type

Integrating a data type is UNITE's most typical large task. Storing the data is
the easy part; the work is connecting it with everything that can be connected:
other modalities, search, downloads, visualizations, datasets and analyses.

The playbook with all questions and the touch-point table is
`unite-meta/docs/integrating-a-data-type.md`. Read it, and the topic documents
it links (domain, ingestion, processing, search, datasets, analysis), before
starting. This skill is the procedure around it.

## Phase 1: settle the design with the owner

Ask the playbook questions **one at a time** and wait for the answer; do not
present the whole list at once. Cover at least:

1. What the data is, and **deep or loose integration** (searchable values vs
   files with metadata).
2. The **sample** of the primary assay, its file format, and how the data is
   usually produced (the upstream analysis and its output formats).
3. Whether the **genome build** matters (position-based data must match the
   instance's build).
4. The **UNITE format** (TSV and JSON): normalized names, correct terminology,
   lowercase identifiers; which common formats to accept through readers.
5. **Re-upload semantics** (replace, merge, upsert) per sample or entity.
6. Its path through the system: search filters, downloads, index (existing
   collection or a new one, connection point, stage order), statistics and
   availability flags, portal pages, genomic profile, datasets page, analyses.

Check Jira ("Known Issues" and "Improvements and Ideas") for related issues and
directions. Record every decision, with owner and date, in the relevant topic
documents (usually `domain.md`, `data-ingestion.md`, `search-and-access.md`)
before writing code.

## Phase 2: write the change plan

From the touch-point table in the playbook, produce a plan listing, per
repository, the concrete files to add or change and why. Include the
documentation of each repository (`README.md`, `Docs/`, `AGENTS.md`). Show the
plan to the owner and adjust it before implementing.

## Phase 3: implement in dependency order

Shared libraries come first because consumers pin published versions (see the
`publish-library` skill).

1. **Model**: `unite-data` entities, mappers, enums, constants and `Have*`
   checks; publish a new version.
2. **Migration**: `unite-data-migrations` (see `docs/sql-migrations.md`);
   review `Up()`/`Down()`.
3. **Index models and search**: `unite-indices` documents, availability flags,
   index services, filters and search stages if needed; publish.
4. **Feed**: endpoints, submission models, readers, validators, handler,
   writer, indexing (usually `unite-feed-omics`); also availability flags and
   statistics in the other feeds' index creators.
5. **API**: `unite-composer` resources, downloads, genomic profile if needed.
6. **Discovery**: `unite-data-source` data type key, route and `Docs/types.md`.
7. **Portal**: `unite` pages, filters, tables, datasets views, upload
   templates, download options, profile tracks.
8. **Analyses**: only those agreed in phase 1 (see `docs/analysis-pipeline.md`).

Work on a feature branch from `dev` in each repository that has `dev` (on
`main` in library repositories). Commit per repository; the owner pushes and
opens pull requests.

## Phase 4: verify

- Build every changed repository; consumers against the new package versions.
- Submit test data through the API and the portal; check review, integration,
  indexing, search with the new filters, downloads, the datasets page and the
  agreed analyses. Use the `run-service-locally` skill for services under
  change, and remove the test data afterwards.
- Reindex where index models changed.
- Report what was verified, what needs the owner's manual check in the UI, and
  places of the touch-point table deliberately left out.

## Notes

- Previous integrations missed places; the playbook lists them. Check every row
  of the touch-point table, even when it seems unrelated.
- Add newly discovered touch points to the playbook.
