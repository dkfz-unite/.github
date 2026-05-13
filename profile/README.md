# DKFZ UNITE
Welcome to the DKFZ UNITE organization on GitHub.

UNITE is platform for integration and analysis of different types of biomedical data.

## Data Types
The following data types are currently supported:

- Patient data
    - Donors - general patient data including projects and studies the patient is part of
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
- Genome data
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
- Data storage - data is standardized, integrated and stored in central database in structured form
- Data annotation - data is annotated using different tools (e.g. Ensembl VEP, Ensembl Database)
- Data indexing - data is indexed for fast search and retrieval
- Web interface - data can be accessed via web interface
    - Cross reference search
    - Dataset management tools
    - Vizualization tools
    - Data export tools
- Identity management
    - Different identity providers (Integrated or LDAP)
    - Users management - access to data is restricted to users in allow list with different permissions
    - Workers management - access to data can be granted to external services (e.g. for automatic data submission or data analysis)
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
- Docker integration - all components are dockerized and can be deployed on any supported platform

## Further reading
- [Installation](https://github.com/dkfz-unite/unite-environment) - installation instructions
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
