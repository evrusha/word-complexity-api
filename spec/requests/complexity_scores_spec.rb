require "rails_helper"

RSpec.describe "Complexity scores" do
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:scoring_job) { ScoringJob.last }

  def submit(body) = post(complexity_scores_path, params: body, headers:)

  def error_message = response.parsed_body.dig("error", "message")

  describe "POST /complexity-score" do
    it "enqueues one scoring job per word" do
      expect { submit %w[happy water].to_json }.to have_enqueued_job(ScoreWordJob).exactly(2).times
    end

    it "normalizes and deduplicates the words" do
      submit [ "Happy", " happy ", "WATER" ].to_json

      expect(scoring_job.word_scores.map(&:word)).to eq(%w[happy water])
    end

    {
      "an object" => [ { words: [ "happy" ] }, "request body must be a JSON array of words" ],
      "an empty array" => [ [], "word list must not be empty" ],
      "non-string items" => [ [ "happy", 42 ], "request body must be a JSON array of words" ],
      "malformed words" => [ [ "happy", "h4ppy", "" ], 'invalid words: "h4ppy", ""' ],
      "overly long words" => [ [ "a" * 51 ], "invalid words: \"#{"a" * 47}...\"" ],
      "too many words" => [ ("aa".."zz").first(101), "word list must not exceed 100 words" ]
    }.each do |description, (payload, message)|
      it "rejects #{description}" do
        expect { submit payload.to_json }.not_to change(ScoringJob, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(error_message).to eq(message)
      end
    end
  end

  describe "GET /complexity-score/:job_id" do
    it "reports a pending job without results" do
      submit %w[happy].to_json
      get complexity_score_path(scoring_job)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("job_id" => scoring_job.id, "status" => "pending")
    end

    it "reports a job in progress without partial results" do
      stub_dictionary("happy")
      submit %w[happy water].to_json
      ScoreWordJob.perform_now(scoring_job.word_scores.first)

      get complexity_score_path(scoring_job)

      expect(response.parsed_body).to eq("job_id" => scoring_job.id, "status" => "in_progress")
    end

    it "omits errors when every word is scored" do
      stub_dictionary("happy")

      perform_enqueued_jobs { submit %w[happy].to_json }
      get complexity_score_path(scoring_job)

      expect(response.parsed_body).to eq("job_id" => scoring_job.id, "status" => "completed", "result" => { "happy" => 3.0 })
    end

    it "responds with not found for a malformed job id" do
      get complexity_score_path("abc123")

      expect(response).to have_http_status(:not_found)
    end
  end
end
