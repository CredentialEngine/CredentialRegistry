#!/usr/bin/env bash

if [ "$CLOUD66_STACK_ENVIRONMENT" == "production" ]; then
  echo "license_key: $NEW_RELIC_LICENSE_KEY" | tee -a /etc/newrelic-infra.yml
  curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | apt-key add -
  printf "deb [arch=amd64] http://download.newrelic.com/infrastructure_agent/linux/apt bionic main" | tee -a /etc/apt/sources.list.d/newrelic-infra.list
  apt-get update
  apt-get install newrelic-infra -y
fi
