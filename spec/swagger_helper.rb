require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("docs/api").to_s
  config.openapi_format = :yaml
  config.openapi_no_additional_properties = true

  config.openapi_specs = {
    "openapi.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "Word Complexity Score API",
        version: "1.0.0",
        description: <<~MARKDOWN
          Scores words by `(synonyms + antonyms) / definitions`, using the [Free Dictionary API](https://dictionaryapi.dev).

          Scoring is asynchronous: submit a list of words, then poll the job until its status is `completed`.
        MARKDOWN
      },
      servers: [ { url: "http://localhost:3000", description: "Local development" } ],
      tags: [ { name: "Complexity score", description: "Submit words and fetch their scores" } ],
      components: {
        schemas: {
          WordList: {
            type: :array,
            minItems: 1,
            maxItems: WordList::MAX_SIZE,
            items: {
              type: :string,
              maxLength: WordList::MAX_WORD_LENGTH,
              description: "ASCII letters, optionally joined by hyphens, apostrophes or single spaces. Trimmed, lowercased and deduplicated."
            },
            example: %w[happy joyful sad angry]
          },
          JobAccepted: {
            type: :object,
            required: %w[job_id],
            properties: { job_id: { "$ref" => "#/components/schemas/JobId" } }
          },
          JobId: { type: :string, format: :uuid, example: "72f2ceea-99ef-4dd4-884c-62b8084b32aa" },
          Job: {
            type: :object,
            required: %w[job_id status],
            properties: {
              job_id: { "$ref" => "#/components/schemas/JobId" },
              status: { type: :string, enum: ScoringJob.statuses.keys },
              result: {
                type: :object,
                description: "Score per word, in submission order. `null` when the word could not be scored. Present once the job is completed.",
                additionalProperties: { type: :number, nullable: true }
              },
              errors: {
                type: :object,
                description: "Reason per word that could not be scored. Omitted when every word was scored.",
                additionalProperties: { type: :string }
              }
            }
          },
          Error: {
            type: :object,
            required: %w[error],
            properties: {
              error: {
                type: :object,
                required: %w[code message],
                properties: { code: { type: :string }, message: { type: :string } }
              }
            }
          }
        }
      }
    }
  }
end
