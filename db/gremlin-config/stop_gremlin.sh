#!/bin/bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

GREMLIN_YAML=conf/server.yaml $SCRIPT_DIR/bin/gremlin-server.sh stop
