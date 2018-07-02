#!/usr/bin/env bash

# Create shared folders.
mkdir -p $STACK_BASE/shared/db/gremlin

# Set permissions for shared db folder root.
chown -R nginx:app_writers $STACK_BASE/shared/db
chmod -R g+rws $STACK_BASE/shared/db

# Delete existing folders that should be shared.
rm -rf $STACK_PATH/db/gremlin

# Create symlinks.
ln -nsf $STACK_BASE/shared/db/gremlin $STACK_PATH/db/gremlin
