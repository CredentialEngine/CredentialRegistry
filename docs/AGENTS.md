# Agent Instructions

## Running Tests

Prefer the Docker test environment for full-suite verification.

Before running tests, make sure the default development compose stack is not
using port `5432`:

```sh
docker compose down
```

The documented test command is:

```sh
docker compose -f docker-compose.test.yml \
  up --abort-on-container-exit --exit-code-from app
```

In this repo, the app reads database settings from `POSTGRESQL_*` variables,
not only `DATABASE_URL`. If the compose test stack fails to resolve or connect
to Postgres, run the suite with explicit database overrides:

```sh
docker compose -f docker-compose.test.yml run --rm \
  -e POSTGRESQL_ADDRESS=postgres \
  -e POSTGRESQL_USERNAME=postgres \
  -e POSTGRESQL_PASSWORD=postgres \
  -e POSTGRESQL_DATABASE=metadataregistry_test \
  app
```

After a test run, clean up the test stack:

```sh
docker compose -f docker-compose.test.yml down
```

If the test image needs to be rebuilt:

```sh
docker compose -f docker-compose.test.yml build app
```

On Apple Silicon, the test Dockerfile may need an amd64 build because it
installs architecture-specific RPMs:

```sh
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose -f docker-compose.test.yml build app
```

If that build fails because `Dockerfile.test` is based on UBI8 while `rpms/`
contains EL10 RPMs, do not spend time debugging Docker unless the task is
specifically about the test image. Use the existing image with the explicit
`POSTGRESQL_*` overrides above, and report the image build issue separately.
