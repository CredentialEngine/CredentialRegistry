# Local RSpec tests

## 1. Prerequisites

* Docker Engine ≥ 20.10  
* Docker Compose v2 (`docker compose` command)

## 2. One-time setup

```bash
# From the repository root
mkdir -p tmp          # tests expect Rails.root/tmp to exist
touch tmp/.keep       # keeps the folder in Git
```
(If you prefer, you can instead edit `Dockerfile.test` so the entrypoint does `mkdir -p /app/tmp` automatically.)

## 3. Build the test image

```bash
docker compose -f docker-compose.test.yml build app
```

The first build takes a few minutes; subsequent builds are cached.

## 4. Run the test suite

```bash
# Run until completion, stop containers, return RSpec exit-code
docker compose -f docker-compose.test.yml \
  up --abort-on-container-exit --exit-code-from app
```

What happens:

1. `postgres:` service starts (PostgreSQL 16, identical to CI).
2. `app:` container starts, waits for Postgres health-check.
3. Entry point:
   * migrates the test DB (`bundle exec rake db:migrate`)
   * executes `bundle exec rspec`
4. Docker Compose propagates the RSpec exit code to your shell.

Coverage reports:

- JSON (for SonarQube): `coverage/coverage.json`
- HTML (human-readable): `coverage/index.html`

Open the HTML report in your browser after a run:

```bash
open coverage/index.html  # macOS
# xdg-open coverage/index.html  # Linux
```

## 5. Iterating quickly

* Drop into a shell:

  ```bash
  docker compose -f docker-compose.test.yml run --rm app bash
  ```

  Inside you’re at `/app` with all gems installed; run any command
  (`rspec`, `rubocop`, etc.) without the image rebuild.

* Re-run only failing specs:

  ```bash
  docker compose -f docker-compose.test.yml \
    run --rm app bundle exec rspec --only-failures
  ```

## 6. Cleaning up

```bash
# Stop and remove containers
docker compose -f docker-compose.test.yml down

# Remove the Postgres volume to start with a fresh cluster
docker compose -f docker-compose.test.yml down -v
```
