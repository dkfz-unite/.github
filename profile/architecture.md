# Architecture
The platform is build from multiple components which communicate with each other via REST API.

### Environment
[Docker](https://www.docker.com/) is used to deploy the platform. Each component is a separate docker container. To locate each other, containers share a common docker network.

### Infrastructural Components
- [Postgresql](https://www.postgresql.org/) - domain and identity data storage
- [Mysql](https://www.mysql.com/) - Ensembl data storage (required verson 5.6)
- [MongoDB](https://www.mongodb.com/) - submission and cache data storage
- [Elasticsearch](https://www.elastic.co/) - data index storage an dsearch engine

### Application Components
- Ensembl Data - customized installation of Ensembl database
- Ensembl VEP - customized installation of Ensembl variant effect predictor (VEP)
- Donors Feed - donors data submission API and indexing service
- Images Feed - images data submission API and indexing service
- Specimens Feed - specimens data submission API and indexing service
- Genome Feed - genome data submission API and indexing service
- Composer - data access and search service API
- Identity - identity management and authentication service API
- Portal - web interface

### Diagram
Architecture diagram of the platform and its components.
![Architecture](images/architecture.svg "Architecture")
