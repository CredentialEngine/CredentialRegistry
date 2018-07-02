## Searching with Gremlin

In addition to the regular search API, the Credential Registry provides a
property graph database that is accessible using Apache Tinkerpop's
[Gremlin](http://tinkerpop.apache.org/) language and tools.

### Data model

The following rules are followed when transforming JSON-LD documents into
objects in the property graph:

- Each JSON-LD document is a vertex.
- Property values, when they are literals, become properties in the vertex.
- Arrays of literal values become arrays of properties in the vertex.
- Property values that are documents become vertices.
  - The edge between the parent document and the inner document is identified
    by the property key.
- Property values that reference other documents with `@id`  become vertices.
  - The edge between the parent document and the inner document is identified
    by the property key.

![CE graph data model](images/property_graph.jpg "CE graph data model")

### Connecting to the Credential Registry Gremlin server

```
Sandbox URL: sandbox.credentialengineregistry.org
Sandbox Port: 8182
Sandbox username: credentialregistry
Sandbox password: 8Zc7NJIMFDSrUIv
```

The server uses SSL and SASL authentication (username/password).

For prototyping queries, we suggest using
[Gremlin Console](https://tinkerpop.apache.org/docs/current/tutorials/the-gremlin-console/).
See [remote-secure.yaml](../db/gremlin-config/console/remote-secure.yaml) for an example console configuration.

After downloading Gremlin Console and the example configuration, start a new
session by running `bin/gremlin.sh` from the console root.

```
$ db/gremlin/console/bin/gremlin.sh
gremlin> :remote connect tinkerpop.server /path/to/config.yaml session
gremlin> :remote console
gremlin> g.V().has(label,of('ceterms_BachelorDegree')).limit(5).valueMap('ceterms_name')
==>{ceterms_name=[Bachelor of Science in Information Technology]}
==>{ceterms_name=[Bachelor of Science in Computer Science]}
==>{ceterms_name=[Bachelor of Science in Information Technology]}
==>{ceterms_name=[Bachelor of Science in Surveying Engineering]}
==>{ceterms_name=[Bachelor of Professional Studies - Organizational Leadership]}
gremlin>
```

### Example queries

See the documentation file for [example Gremlin queries](07_search_03_gremlin_queries.md).

### Backend implementation

Our Gremlin endpoint is backed by a Neo4j database. Currently, importing data
into the graph happens in a nightly process which renders the graph features
unavailable while it's running. This will change in the feature.

The graph that is exposed by Gremlin is read-only.

### Rake tasks

| Task | Description |
| --- | --- |
| `gremlin:install` | Installs Gremlin server |
| `gremlin:install_console` | Installs Gremlin console (local development) |
| `gremlin:start` | Starts Gremlin server |
| `gremlin:stop` | Stops Gremlin server |
| `gremlin:import` | Imports CR data into the graph |
| `gremlin:init_neo4j` | Prepares the Neo4j instance for Gremlin usage |
| `gremlin:console` | Starts Gremlin console |
