#!/bin/bash

source /etc/profile

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

$SCRIPT_DIR/stop_gremlin.sh

GREMLIN_YAML=conf/server.yaml \
  LOG_DIR=$GREMLIN_LOG_FOLDER \
  $SCRIPT_DIR/bin/gremlin-server.sh start
