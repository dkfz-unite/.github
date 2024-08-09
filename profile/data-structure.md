# Data Structure
Platform supports and integrates various types of data.

## Data Types
Currently supported data is the following:
- Donors
  - [General](https://github.com/dkfz-unite/unite-donors-feed/blob/main/Docs/api-models-donors.md) - general information of a patients
  - [Clinical](https://github.com/dkfz-unite/unite-donors-feed/blob/main/Docs/api-models-base-clinical.md) - patient clinical data
  - [Treatments](https://github.com/dkfz-unite/unite-donors-feed/blob/main/Docs/api-models-base-treatment.md) - patient treatments
- Images
  - [General](https://github.com/dkfz-unite/unite-images-feed/blob/main/Docs/api-models-image.md) - metadata of different types of images
    - [MRI](https://github.com/dkfz-unite/unite-images-feed/blob/main/Docs/api-models-mris.md)
  - Radiomics features extraction analysis (RFE) data
    - [Sample](https://github.com/dkfz-unite/unite-images-feed/blob/main/Docs/api-models-base-sample.md) metadata
    - [Radiomics features](https://github.com/dkfz-unite/unite-images-feed/blob/main/Docs/api-models-radiomics.md)
- Specimens
  - [General](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-specimen.md) - general information of specimens and their hierarchy
    - [Material](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-material.md) - all donor derived materials
    - [Line](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-line.md) - cell lines
    - [Organoid](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-organoid.md) - organoids
    - [Xenograft](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-xenograft.md) - xenografts
  - [Molecular](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-base-molecular.md) - specimens molecular data
  - [Interventions](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-base-intervention.md) - speciment interventions
  - Drugs screening analysis (DSA) data
    - [Sample](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-base-sample.md) metadata
    - [Drug screenings](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api-models-drugs.md)
- Genome
  - DNA analysis data
    - [Sample(s)](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-sample.md) metadata (target and/or matched)
    - Variants of different types
      - [Simple somatic mutations (SSM)](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-dna-ssm.md) - SNV/INDEL
      - [Copy number variants (CNV)](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-dna-cnv.md)
      - [Structural variants (SV)](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-dna-sv.md)
  - Bulk RNA analysis data
    - [Sample](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-sample.md) metadata
    - [Gene expressions](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-rna-exp.md)
  - Single cell RNA analysis data
    - [Sample](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-sample.md) metadata
    - [Gene expressions per cell](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api-models-rnasc-exp.md) - results metadata

### Diagram
The following diagram shows the structure of the data and how the data is connected.  
![Structure](images/data-structure.svg "Structure")

## API
The data can be uploaded to the portal either directly via portal's UI or using the following API:
- [Donors Feed](https://github.com/dkfz-unite/unite-donors-feed/blob/main/Docs/api.md) - all donors related daata
- [Images Feed](https://github.com/dkfz-unite/unite-images-feed/blob/main/Docs/api.md) - all images related data
- [Specimens Feed](https://github.com/dkfz-unite/unite-specimens-feed/blob/main/Docs/api.md) - all specimens related data
- [Genome Feed](https://github.com/dkfz-unite/unite-genome-feed/blob/main/Docs/api.md) - all genomic information 