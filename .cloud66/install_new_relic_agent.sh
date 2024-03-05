#!/usr/bin/env bash

if [ "$CLOUD66_STACK_ENVIRONMENT" == "production" ]||[ "$CLOUD66_STACK_ENVIRONMENT" == "sandbox" ]; then
  curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=$NEW_RELIC_API_KEY NEW_RELIC_ACCOUNT_ID=$NEW_RELIC_ACCOUNT_ID /usr/local/bin/newrelic install -y
fi
