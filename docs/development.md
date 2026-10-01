# Development

## Requirements

- Ruby 3.4.7
- PostgreSQL
- Redis

## Setup

```sh
bundle install
bin/rails db:prepare
bin/dev
```

`bin/dev` starts Puma on `http://localhost:3000` and a Sidekiq worker. Without a worker, jobs stay `pending`.

Set `REDIS_URL` if Redis is somewhere else or shared with other projects:

```sh
REDIS_URL=redis://localhost:6379/5 bin/dev
```

## Useful pages

| URL | What |
|-----|------|
| `http://localhost:3000` | Page for submitting words and watching a job complete |
| `http://localhost:3000/api-docs` | Swagger UI |
| `http://localhost:3000/sidekiq` | Sidekiq dashboard, development only |

## Tests

```sh
bundle exec rspec
bin/rubocop
```

The specs never call the real dictionary: HTTP is stubbed with WebMock using real responses recorded in `spec/fixtures/files/dictionary`.

| Path | What it covers |
|------|----------------|
| `spec/api` | API contract: every endpoint and status code, validated against the OpenAPI schemas |
| `spec/requests` | API behaviour: validation rules, normalization, job states |
| `spec/jobs` | Scoring, retries and job completion |
| `spec/models` | Dictionary client, response parsing, caching |

`bin/ci` runs RuboCop, the specs and the security checks.

## API documentation

The OpenAPI spec in `docs/api/openapi.yaml` is generated from `spec/api`, so every documented response is backed by a passing test. After changing the API, update the spec and regenerate:

```sh
RAILS_ENV=test bin/rails rswag:specs:swaggerize
```

## Configuration

| Variable | Default |
|----------|---------|
| `DATABASE_URL` | local socket, see `config/database.yml` |
| `REDIS_URL` | `redis://localhost:6379` |
| `DICTIONARY_API_URL` | `https://api.dictionaryapi.dev/api/v2/entries/en/` |
| `SIDEKIQ_CONCURRENCY` | `10` |
| `RAILS_MAX_THREADS` | `3` |

Timeouts and cache TTL are in `config/dictionary.yml`. The database pool is sized to the larger of `RAILS_MAX_THREADS` and `SIDEKIQ_CONCURRENCY`.
