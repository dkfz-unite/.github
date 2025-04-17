# Architecture
The platform is build from multiple components which communicate with each other over REST API.

### Environment
[Docker](https://www.docker.com/) is used to deploy the platform. Each component is a separate docker container. To locate each other, containers share a common docker network.

### Infrastructural Components
- [Postgresql](https://www.postgresql.org/) - domain and identity data storage
- [Mysql](https://www.mysql.com/) - Ensembl data storage (required verson 5.6)
- [MongoDB](https://www.mongodb.com/) - submission and cache data storage
- [Elasticsearch](https://www.elastic.co/) - data index storage an dsearch engine

### Application Components
- [Ensembl Data](https://github.com/dkfz-unite/unite-ensembl-data) - customized installation of Ensembl database
- [Ensembl VEP](https://github.com/dkfz-unite/unite-ensembl-vep) - customized installation of Ensembl variant effect predictor (VEP)
- [Donors Feed](https://github.com/dkfz-unite/unite-feed-donors) - donors data submission API and indexing service
- [Images Feed](https://github.com/dkfz-unite/unite-feed-images) - images data submission API and indexing service
- [Specimens Feed](https://github.com/dkfz-unite/unite-feed-specimens) - specimens data submission API and indexing service
- [Genome Feed](https://github.com/dkfz-unite/unite-feed-genome) - genome data submission API and indexing service
- [Identity](https://github.com/dkfz-unite/unite-identity) - identity management and authentication service API
- [Composer](https://github.com/dkfz-unite/unite-composer) - data access and search service API
- [Analysis](https://github.com/dkfz-unite/unite-analysis) - analysis service API
- [Portal](https://github.com/dkfz-unite/unite) - web interface

### Diagram
The following diagram shows architecture of the platform and its components.
![Architecture](images/architecture.svg "Architecture")
