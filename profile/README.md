# DKFZ UNITE
Welcome to the DKFZ UNITE organization on GitHub.

UNITE is platform for integration and analysis of different types of biomedical data.

The primary users are researchers, bioinformaticians, and physicians working in
the relevant biomedical domain. Administrators, often bioinformaticians, review
data submissions and manage installation and data-source configuration.

The initial focus is cancer research. Data is linked around anonymized donors
and can be searched and filtered to create datasets (donor cohorts), which users
can analyze individually or compare using available analysis methods.

See the [project onboarding](../README.md) and [domain model](../docs/domain.md)
for shared context, intentional constraints, and unresolved questions.

## Data Types
The following data types are currently supported:

- Patient data
    - Donors - anonymized patient data, with optional project assignments and study information
    - Clinical data
    - Treatments data
- Images data - metadata of images (not the images themselves)
    - Images data of different types (MR)
    - Radiomics features data
- Specimens data - donor specimens data and specimens hierarchy
    - Specimens of different types (Material, Line, Organoid, Xenograft)
    - Molecular data
    - Tumor classification data
    - Interventions data
    - Drugs screening data
- Omics data
    - Variants - SMs, CNVs, SVs
    - CNV profiles
    - Methylation data
    - Gene expressions data
    - Single cell gene expression data
    - Protein expressions data


## Functionality
The core functionality of the platform is following:

- Data submission - data can be submitted in different formats via web interface or API
- Data validation - data is validated before it is stored in the database
- Data review - accepted submissions are staged in MongoDB with SQL tasks; the standard workflow requires administrator approval before domain integration
- Data storage - deeply integrated data is standardized and stored in structured form; loose integration registers metadata and links to externally hosted files
- Data annotation - data is annotated using different tools (e.g. Ensembl VEP, Ensembl Database)
- Data indexing - data is indexed for fast search and retrieval
- Web interface - data can be accessed via web interface
    - Cross reference search
    - Dataset management tools - save named search-criteria presets with descriptions; view matching data and modality availability
    - Vizualization tools
    - Data export tools
- Identity management
    - Different identity providers (Integrated or LDAP)
    - Users management - private instances require an administrator-managed email access list; public instances allow registration without it
    - Permissions - `Data.Read` and `Data.Write`, with a configured root administrator
    - Workers/tokens - administrators can issue long-lived JWTs for service access; currently used by `unite-data-source`
    - Authentication/Authorization - access to data is restricted to authenticated users/workers
- Analysis
    - Differential gene expression (DESeq2)
    - Differential protein expression (Limma)
    - UMAP of protein expression profiles (Limma)
    - Differential methylation (Minfi)
    - PCA of methylation profiles (Minfi)
    - Donors survival/progression curve estimation (Kaplan-Meier)
    - Single cell RNA dataset creation workflow
    - Gene aleration frequency (Oncogrid)
    - CNV profiles grid (Oncogrid for CNV profiles)
- Docker integration - all components are dockerized and can be deployed on any supported platform

`unite-data-source` can discover configured files using sample sheets or custom
crawlers, submit to the relevant feed, and host external resources. Integrated
values can be indexed for search; loose resources contribute availability
information, while their file contents are retrieved for analysis preparation.
Original files are not routinely relocated or copied to portal storage.

See [Data ingestion and review](../docs/data-ingestion.md) for the difference
between successful submission, approval, integration, and completed indexing.

Variants are annotated asynchronously through the Ensembl VEP wrapper;
gene/protein expression is enriched through the Ensembl Data wrapper during
submission processing. Indexing workers build Elasticsearch documents from
SQL data. See [Processing pipeline](../docs/processing-pipeline.md) for task
types, status meanings, and code navigation.

Cross-reference search connects separate index collections through compact
navigation fields and sequential ID aggregation. Server-side personal criteria
restrict the search scope to accessible projects. Combined specimen/mutation
criteria must match the same specimen. See [Search and access](../docs/search-and-access.md).

Saved datasets are stored in MongoDB `user-data.datasets`. They define search
presets whose matching data can change as indexed data or access changes. The
datasets page uses search statistics to display modality availability and help
choose analyses. See [Datasets and portal](../docs/datasets-and-portal.md) for
storage, UI behavior, and code navigation.

Analysis runs through Prepare and Process phases with shared-volume inputs and
method-specific R/Python runners or internal processing. Busy runners are
retried; preparation/computation failures require manual restart. Analyses and
remaining files are retained until user deletion. The portal visualizes result
data itself; Scell's AnnData output uses an on-demand Cell-x-Gene viewer in a
proxied iframe. See [Analysis pipeline](../docs/analysis-pipeline.md).

Identity also cleans expired sessions and inactive accounts. Account deletion
removes saved datasets and analyses; file cleanup needs verification across
deletion paths. The shared `UNITE_API_KEY` signs/verifies JWTs. See
[Identity and lifecycle](../docs/identity-and-lifecycle.md).

## Work in progress and planned extensions

- Private projects are under development. The intended rule limits access to
  associated data to project members. A donor assigned to any public project
  is visible even if it also belongs to a private project; access across several
  private projects remains to be clarified.
- Worker-token scope for private projects is not yet defined.
- RNA gene fusions are planned.
- Non-human donors are a possible future extension, not a current capability
  established by this documentation.

## Further reading
- [Installation](https://github.com/dkfz-unite/unite-env) - installation instructions
- [Architecture](./architecture.md) - architecture of the platform and its components
- [Data structure](./data-structure.md) - data structure of the platform
<!-- - [Index structure](index-structure.md) - index structure of the platform -->


<!--
**Here are some ideas to get you started:**

🙋‍♀️ A short introduction - what is your organization all about?
🌈 Contribution guidelines - how can the community get involved?
👩‍💻 Useful resources - where can the community find your docs? Is there anything else the community should know?
🍿 Fun facts - what does your team eat for breakfast?
🧙 Remember, you can do mighty things with the power of [Markdown](https://docs.github.com/github/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
-->
