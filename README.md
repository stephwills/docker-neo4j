# The InformaticsMatters neo4j container image

[![CodeFactor](https://www.codefactor.io/repository/github/informaticsmatters/docker-neo4j/badge)](https://www.codefactor.io/repository/github/informaticsmatters/docker-neo4j)

## Building the database
Neo4j build for running the Fragment Network merging database.

First, clone the github repo and navigate into the docker-neo4j directory.
Before building the database, build the logs and graph dirs:

```angular2html
mkdir neo4j-container-logs neo4j-container-graph
```

The database files are available at https://zenodo.org/records/13501312 and https://zenodo.org/records/13509276.
Note: the configuration is slightly different/stripped back to that described in the paper and will undergo some testing.

The data files for the graph database should be saved in `neo4j-import`.
They are loaded using the `load-neo4j.sh` file.
The general format for the data files is to have a csv.gz containing the node or edge data, and the header file specifies the name of the property.

Warning: these files and the compiled database are **large**. The data files (before compilation) take up ~80 GB. The compiled database requires up to ~2 TB.

The database can then be built using the following commands:

    $ docker run --user $(id -u):$(id -g) \
        -v ./files:/plugins
        -v ./neo4j-import:/data-import
        -v ./neo4j-container-logs:/graph-logs
        -v ./neo4j-container-graph:/graph
        -p 7474:7474
        -p 7687:7687
        -e NEO4J_AUTH=neo4j/blob1234
        -e NEO4J_dbms_directories_data=/graph
        -e NEO4J_dbms_directories_logs=/graph-logs
        -e IMPORT_DIRECTORY=/data-import
        -e IMPORT_TO=graph
        -e EXTENSION_SCRIPT=/data-import/load-neo4j.sh
        -e GRAPH_PASSWORD=blob1234
        -e NEO4J_USERNAME=neo4j
        -e NEO4J_dbms_security_procedures_unrestricted=algo\.\* informaticsmatters/neo4j:4.4.9


If the database has already been built but the docker container has been stopped, you can run a new one with the pre-compiled database with: 

    $ docker run --user $(id -u):$(id -g)
        -v ./files:/plugins
        -v ./neo4j-container-logs:/graph-logs
        -v ./neo4j-container-graph:/graph
        -p 7474:7474
        -p 7687:7687
        -e NEO4J_AUTH=neo4j/blob1234
        -e NEO4J_dbms_directories_data=/graph
        -e NEO4J_dbms_directories_logs=/graph-logs
        -e GRAPH_PASSWORD=blob1234
        -e NEO4J_USERNAME=neo4j
        -e NEO4J_dbms_security_procedures_unrestricted=algo\.\* informaticsmatters/neo4j:4.4.9

Monitor the logs when the container's running to ensure the database build,
which can take considerable time for non-trivial graphs, progresses without error: -

    $ docker logs -f <container-id>

## Data files

Nodes are stored in the `nodes.csv.gz` file and property names are defined in `header-nodes.csv`.
Note: the compound vendor IDs have been removed and have been assigned a random name/index.

The edges are stored in the `edges_IDX.csv.gz` files and property names are defined in and `header-edges.csv`.
The edge properties include the SMILES of the starting node, the end node, the SMILES of the synthon (the substructure being added or removed in the transformation),
the SMILES of the core (the remainder of the molecule; [Xe] denotes the attachment point), the number of rings, the number of atoms (including the attachment point atom) 
and the pharmacophore fingerprint (named prop_pharmfp). In theory, you can use your own nodes and data files and use this docker to build the database.

The code to build the original database is available from https://github.com/InformaticsMatters/fragmentor.
This repo does not contain the IsoMol and Supplier nodes/edges described in https://github.com/InformaticsMatters/fragmentor. 

## Usage with Python API

To access the database using the Python API you can use the following:

```angular2html
from neo4j import GraphDatabase

USERNAME = "neo4j"
PASSWORD = "blob1234"
driver = GraphDatabase.driver("bolt://localhost:7687", auth=(USERNAME, PASSWORD))
```

## Usage with Cypher shell

To use the cypher shell, you can use the following:
```angular2html
docker exec -it <CONTAINER_ID> bash
cypher-shell -u neo4j -p blob1234
```
## Running post-DB cypher commands
The image contains the ability to run a series of cypher commands
after the database has started. It achieves this by running a provided
`cypher-runner.sh` script located in this image's `/cypher-runner` directory.
This script is executed towards the end of the `docker-entrypoint.sh`
and runs in the background until the provided cypher commands have been
executed.

All you need to do to run your own early cypher commands
is to provide them in either a `/cypher-runner/cypher-script.once`
or `/cypher-runner/cypher-script.always` file and provide
the neo4j credentials.

An example `.once` script may contain the following index commands: -

    CREATE INDEX ON :F2(smiles);
    CREATE INDEX ON :VENDOR(cmpd_id);
    
An example `.always` script may contain the following cache-warm-up commands: -

    CALL apoc.warmup.run(true, true, true);

>   This command helps improve query performance by quickly [warming up] the
    page-cache by touching pages in parallel optionally loading
    property-records, dynamic-properties and indexes

If the environment variables `NEO4J_USERNAME` and `NEO4J_PASSWORD` are defined,
the scripts will be run in the background automatically.

>   The cypher runner waits for a short period of time after neo4j has been
    given an opportunity to start (about 60 seconds) before the first run of
    the script is attempted. This can be configured in the image (refer
    to the cypher-runner script for the environment variables it inspects).

## docker-entrypoint tweaks
**CAUTION**: We replace the supplied neo4h `docker-entrypoint.sh` script with
our own variant. It adds some extra logic, all identified and briefly documents
by comments that begin `IM-BEGIN` and end with `IM-END`.

## Plugins
We've added the following plugins to the image: -

1. **Neo4j Graph Data Science Library** [gds] from the [community] section of
    the download-centre
    (formally the graph-algorithms-algo library we used in our 3.5 image)
2. **Neo4j Apoc Procedure**, a collection of useful Neo4j Procedures
    from the [apoc] distribution on Maven.
3. **Fragment Knitwork plugin**: has custom function for calculating similarity between ph4 descriptors

>   The changes to `dbms.security.procedures.unrestricted` take place in the
    **Dockerfile** where it's written to `/var/lib/neo4j/conf/neo4j.conf`.

## The enterprise container image
Although a build is made available for the Enterprise container
you are not permitted to use it unless you are in possession of a
valid licence agreement.
    
## The ansible role and playbook
The Ansible role and corresponding playbook has been written to simplify
deployment of the neo4j image along with an associated AWS S3-based graph.

The role deploys an S3-based loader prior to spinning-up the neo4j instance. 

---

[apoc]: https://mvnrepository.com/artifact/org.neo4j.procedure/apoc
[gds]: https://neo4j.com/docs/graph-data-science/current/installation/
[community]: https://neo4j.com/download-center/#community
[warming up]: https://neo4j-contrib.github.io/neo4j-apoc-procedures/3.5/operational/warmup/
