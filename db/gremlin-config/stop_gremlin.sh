#!/bin/bash

GREMLIN_YAML=conf/server_primary.yaml ./primary/bin/gremlin-server.sh stop
GREMLIN_YAML=conf/server_replica.yaml ./replica/bin/gremlin-server.sh stop
