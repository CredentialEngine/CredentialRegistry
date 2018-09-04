#!/bin/bash

./stop_gremlin.sh

GREMLIN_YAML=conf/server_primary.yaml \
	LOG_DIR=$GREMLIN_LOG_FOLDER/primary \
		./primary/bin/gremlin-server.sh start

GREMLIN_YAML=conf/server_replica.yaml \
	LOG_DIR=$GREMLIN_LOG_FOLDER/replica \
		./replica/bin/gremlin-server.sh start
