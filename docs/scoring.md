# Scoring

```
score = (synonyms + antonyms) / definitions
```

## What is counted

The dictionary returns one or more entries per word. Each entry has meanings grouped by part of speech, and each meaning has a list of definitions. Synonyms and antonyms appear on two levels: on a meaning and on individual definitions. In practice most of them sit on the meaning level, so counting only the definition level would score almost every word as `0`.

The score therefore counts:

- **definitions** — every definition across all entries and meanings
- **synonyms** — unique synonyms from both levels across the whole response
- **antonyms** — unique antonyms from both levels across the whole response

Duplicates are removed so a synonym repeated across entries or meanings is counted once.

The result is rounded to two decimals. A word without definitions scores `0.0`.

## Example

`water` (from `spec/fixtures/files/dictionary/water.json`):

| Part of speech | Definitions | Synonyms | Antonyms |
|----------------|-------------|----------|----------|
| noun | 10 | 0 | 12 |
| verb | 9 | 1 | 1 |

Nothing repeats between the two meanings, so the totals are 19 definitions, 1 synonym and 13 antonyms:

```
(1 + 13) / 19 = 0.74
```

## Input normalization

Words are trimmed, lowercased and deduplicated before scoring, so `"Happy"` and `" happy "` are one word. A word is up to 50 characters of ASCII letters, optionally joined by hyphens, apostrophes or single spaces (`ice cream`, `mother-in-law`).

The parsing and counting live in `app/models/dictionary/profile.rb`.
