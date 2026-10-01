# Error handling

## API errors

All errors share one shape:

```json
{ "error": { "code": "unprocessable_content", "message": "word list must not be empty" } }
```

| Status | When |
|--------|------|
| `400` | Body is not valid JSON |
| `404` | Unknown or malformed job id |
| `422` | Body is not an array of strings, is empty, exceeds 100 items, or contains invalid words |
| `429` | More than 30 submissions per minute from one client |
| `503` | The job queue is unreachable; nothing is stored, so the request can be retried safely |

The rate limit applies to submissions only, so polling a job is never throttled.

## Failures while scoring

| Failure | Behaviour |
|---------|-----------|
| Word not in the dictionary (`404`) | Not retried. Word is marked failed with `word not found` |
| Upstream `5xx`, `429`, timeout, connection error | Retried every 5 seconds, 3 attempts total. After that the word is marked failed and the job still completes |
| Malformed upstream response (not a list of entries, HTML, unexpected types) | Treated like an upstream failure and retried as above. Malformed parts inside a valid response are skipped |
| Job record deleted before the worker runs | Job is discarded |
| Infrastructure failure in a worker (e.g. database down) | Sidekiq's default retries with backoff; the word settles once the dependency is back |

A word that could not be scored gets `null` in `result` and its reason in `errors`:

```json
{
  "job_id": "72f2ceea-99ef-4dd4-884c-62b8084b32aa",
  "status": "completed",
  "result": { "happy": 3.0, "sad": null },
  "errors": { "sad": "dictionary responded with 522" }
}
```

## Retries

Upstream failures are raised as `Dictionary::Unavailable` and retried by Active Job (`retry_on` in `app/jobs/score_word_job.rb`):

| Attempt | Starts |
|---------|--------|
| 1 | as soon as a worker picks the word up |
| 2 | 5 seconds after attempt 1 fails |
| 3 | 5 seconds after attempt 2 fails |

If the third attempt fails too, the word is marked `failed` and the job completes as usual. The error reported for the word is one of:

- `dictionary responded with <status>`
- `dictionary timed out`
- `dictionary request failed`
- `dictionary returned an unexpected response`

The error is not re-raised, so these words never show up in Sidekiq's Retries or Dead sets. Each retry is a new job scheduled for later, so a word waiting for its next attempt is listed under **Scheduled** in the Sidekiq dashboard. While any word is waiting, the job stays `in_progress`.

Failed lookups are never cached, so the next request for the same word goes to the dictionary again.

## Upstream behaviour

The dictionary sits behind Cloudflare. When its origin server is unavailable, Cloudflare waits about 20 seconds and responds with `522`. Popular words may still return `200` in that state, because Cloudflare serves a stale cached copy (`cf-cache-status: STALE`), while less common words fail.

The HTTP timeout is 30 seconds, so a failing word takes about a minute in the worst case: three attempts of ~20 seconds plus two 5-second pauses. Retries are kept short on purpose, so one broken word is reported quickly instead of holding the whole job back.
