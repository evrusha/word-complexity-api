# Word Complexity Score API

Asynchronous API that scores how "complex" a word is, based on the [Free Dictionary API](https://dictionaryapi.dev):

```
score = (synonyms + antonyms) / definitions
```

Rails 8.1 (API mode), PostgreSQL, Sidekiq, Redis, Ruby 3.4.

## Quick start

Requires PostgreSQL and Redis running on their default ports.

```sh
bundle install
bin/rails db:prepare
bin/dev
```

Then open `http://localhost:3000` to try it in the browser, or `http://localhost:3000/api-docs` for the interactive API reference.

## API

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/complexity-score` | Submit a JSON array of words, returns `202` with a `job_id` |
| `GET` | `/complexity-score/:job_id` | Job status, and the scores once it is `completed` |

```sh
curl -X POST localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '["happy", "angry", "qwzxv"]'

{ "job_id": "72f2ceea-99ef-4dd4-884c-62b8084b32aa" }
```

```sh
curl localhost:3000/complexity-score/72f2ceea-99ef-4dd4-884c-62b8084b32aa

{
  "job_id": "72f2ceea-99ef-4dd4-884c-62b8084b32aa",
  "status": "completed",
  "result": { "happy": 3.0, "angry": 4.0, "qwzxv": null },
  "errors": { "qwzxv": "word not found" }
}
```

The full contract is in [`docs/api/openapi.yaml`](docs/api/openapi.yaml), generated from the specs in `spec/api`.

## Documentation

| Document | Contents |
|----------|----------|
| [Architecture](docs/architecture.md) | Components, request flow, data model, concurrency, caching |
| [Error handling](docs/error-handling.md) | API errors, upstream failures, retry policy |
| [Scoring](docs/scoring.md) | What is counted and why, with a worked example |
| [Development](docs/development.md) | Setup, tests, regenerating API docs, configuration |
| [OpenAPI spec](docs/api/openapi.yaml) | Machine-readable API contract |
