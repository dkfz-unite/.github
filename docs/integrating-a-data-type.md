# Integrating a new data type

Last updated: 2026-10-12.

"We want to integrate a new data type" is the most typical large task in UNITE.
The difficulty is not storing the data but **connecting it with everything that
can be connected**: other modalities, search, downloads, visualizations,
datasets and analyses. This playbook lists the questions the owner works through
and where the answers lead in the code. It is not exhaustive; add steps when a
new integration reveals one.

Work through the questions with the owner before writing code, and record the
decisions in the relevant topic documents. Background:
[Domain model](domain.md), [Data ingestion](data-ingestion.md),
[Processing pipeline](processing-pipeline.md),
[Search and access](search-and-access.md),
[Datasets and portal](datasets-and-portal.md),
[Analysis pipeline](analysis-pipeline.md).

## 1. Understand the data

- **What is it, and how tightly can it be integrated?** Is it a sample with
  file resources only (loose integration, like methylation arrays or
  single-cell RNA), or values that can be stored and searched (tight
  integration, like variants or expressions)? See
  [deep and loose integration](data-ingestion.md#deep-and-loose-integration).
- **What is the sample of the primary assay, and its file format?** For example
  BAM/CRAM for DNA sequencing, IDAT for methylation arrays, mzML for mass
  spectrometry proteomics.
- **How is it usually analysed into the form in which it is used and reaches
  UNITE?** For example, somatic mutations: a tumour and a normal DNA sample are
  processed and compared, and the result arrives as VCF. The analysis pipeline
  defines which results to expect and their formats.
- **Does the genome build matter?** Data integrated by nucleotide position must
  match the instance's build; see [Genome build](domain.md#genome-build).

## 2. Define the UNITE format

- Design the **standard UNITE format** (TSV and JSON) in which the data should
  arrive, and in which, or very close to which, it is stored. It should be
  programming-friendly and normalized: consistent property names and correct
  terminology. Scientists often name the same thing differently, or wrongly
  (for example calling all simple somatic mutations "SNPs"); the UNITE format
  fixes this ([SM](domain.md#digital-samples-and-results), not SSM or SNP).
- Compare the common formats of the field. They are often not suitable for
  normalized storage as they are; take what is needed, cover everything or most
  of it in the UNITE format.
- Decide which **common formats** to accept in addition, as readers that convert
  to the UNITE format (for example VCF for SM, ACESeq for CNV, DIA-NN for protein
  expressions).

## 3. Store it

- **Database model**: entities and mapping in `unite-data`, migration in
  `unite-data-migrations` ([SQL migrations](sql-migrations.md)).
- **Feed**: endpoints (sample and/or result), submission models, readers,
  validation, handler and writer, usually in `unite-feed-omics` for omics data.
- **Re-upload semantics**: upsert, merge or replace per sample; see
  [Intentional constraints](domain.md#intentional-constraints).
- **Data Source**: data type key, sheet format and route, so the data can be
  discovered and submitted automatically.

## 4. Decide its path through the system

Depending on the type of integration, decide for each part whether and how the
new data type takes part:

- **Search filters**: can its properties be filtered? Which filters can be
  offered (not all are possible), and do they belong to an existing filter
  category or a new one?
- **Downloads**: can it be downloaded? Then it needs download options in the
  download models, download services and TSV mappings. Sample files of loosely
  integrated data (e.g. scRNA, methylation arrays) are not offered for download.
- **Search engine and indexes**:
  - In which form does the data go to Elasticsearch?
  - How is it connected to other modalities, and what is the connection point?
    For example, genes are parts of the DNA; variants affect those parts, so
    they connect to genes by position. Expression data of the same gene connects
    through the specimen, although its digital sample is a different one.
  - Can it be integrated into an existing index collection painlessly, with
    **all** system-wide filters still working? Or does it need a new collection?
  - For a new collection: in which order should cross-reference search visit it,
    so that it connects with the other collections through aggregations?
  - Which **statistics and availability flags** must be calculated for it during
    indexing (per entry and per project)?
- **Portal presentation**: does it need a list page (like mutations) and a
  detail page with its connections to other data? Some types have no own page
  (gene expressions, protein expressions, CNV profiles).
- **Genomic profile**: can and should it be shown in the
  [genomic profile viewer](datasets-and-portal.md#genomic-profile)?
- **Datasets**: show on the datasets page that entries have this data, and show
  its filters when they are set.
- **Analyses**: which analyses are common for this data, how are they
  visualized, which tools and languages are usually used, and which data do they
  require? See [Analysis pipeline](analysis-pipeline.md) for how an analysis is
  added.

## 5. Touch points in the code

Collected from how protein expressions and CNV profiles were integrated
(2026-02 to 2026-08). Paths are relative to each repository.

| Area | Repository | Places |
| --- | --- | --- |
| Model | `unite-data` | Entity (`Unite.Data/Entities/Omics/...`), sample navigation (`Omics/Analysis/Sample.cs`), mapper (`Unite.Data.Context/Mappers/...`), `DomainDbContext`; constants `Constants/DataTypes.cs`, `FileTypes.cs`; enums `AnalysisType` and task types (`Entities/Tasks/Enums`, with their mappers); `Have*`/`HasRelated*` checks in `Unite.Data.Context/Repositories` |
| Migration | `unite-data-migrations` | New migration and model snapshot |
| Feed | usually `unite-feed-omics` | Controller (`Controllers/<Modality>`), submission model, readers and validators (`Models/<Modality>`), submission repository, submission handler and its registration in `SubmissionsWorker`, writer and repositories (`Unite.Omics.Feed/Data`), annotation (`Unite.Omics.Annotations`) if needed, `Docs/` |
| Indexing | feed indices projects | Index entity builder or creator (`Unite.<Type>.Indices/Services`), indexing handler and task service, worker and options |
| Search | `unite-indices` | Index models (`Unite.Indices/Entities`), `DataIndex` and `SampleDataIndex` flags, project stats models; `IndexNames` and index services (`Unite.Indices.Context`); search service, filters collection, base filters, criteria and data filters (`Unite.Indices.Search`) |
| Availability and stats | `unite-feed-donors`, `-specimens`, `-images`, `-omics` | `CreateDataIndex` and stats in each index creator, including `ProjectIndexCreator`; gene, protein and variant builders in the omics feed |
| API | `unite-composer` | Domain controllers and resources (`Resources/Domain/Basic/DataResource.cs`, `Specimens/SpecimenDataResource.cs`), autocomplete, DI; download criteria, repository, service and TSV mapper (`Unite.Composer.Download`); genomic profile (`Unite.Composer/Data/Omics/Ranges`) |
| Portal | `unite` (`Unite.Web/Client/src`) | Domain pages (`domain/omics/...`), navigation and routing, filter models and criteria (`_shared/components/filters`), datasets criteria and data views, tables and available-data summaries, submission types, `DownloadForm.vue`, profile tracks (`visualization/profile`), analysis components |
| Analysis | `unite-analysis` (+ runner repository) | Method service, context loaders and sample metadata, controller and handlers, options; see [Analysis pipeline](analysis-pipeline.md) |
| Discovery | `unite-data-source` | `Handlers/Constants/DataTypes.cs`, `DataUrls.cs`, `ExploringHandler.cs`, `Docs/types.md` |

Places that previous integrations missed, as a reminder to check every row:
the gene index's availability flags lack protein expressions and CNV profiles,
the protein and variant flags lack CNV profiles, the download form has no
separate CNV-profile option, the protein track in the genomic profile is
disabled, and some project statistics exist in the model but are never computed
(protein variation and mutation, CNV profiles per chromosome arm, donors per
diagnosis). These gaps are tracked in Jira.
