require "swagger_helper"

RSpec.describe "Complexity score API", type: :request do
  let(:scoring_job) { ScoringJob.last }

  path "/complexity-score" do
    post "Submit words for scoring" do
      tags "Complexity score"
      operationId "submitWords"
      description "Creates a scoring job and returns immediately. Each word is scored in the background; poll the job for the result."
      consumes "application/json"
      produces "application/json"
      parameter name: :words, in: :body, required: true, schema: { "$ref" => "#/components/schemas/WordList" }

      let(:words) { %w[happy joyful sad angry] }

      response "202", "Job accepted" do
        header "Location", schema: { type: :string, format: :uri }, description: "URL of the created job"
        schema "$ref" => "#/components/schemas/JobAccepted"
        example "application/json", :accepted, { job_id: "72f2ceea-99ef-4dd4-884c-62b8084b32aa" }

        run_test! do
          expect(response.parsed_body["job_id"]).to eq(scoring_job.id)
          expect(response.location).to eq(complexity_score_url(scoring_job))
        end
      end

      response "400", "Body is not valid JSON" do
        schema "$ref" => "#/components/schemas/Error"
        example "application/json", :malformed, { error: { code: "bad_request", message: "request body must be valid JSON" } }

        it "rejects the request" do
          post "/complexity-score", params: "[\"happy\"", headers: { "Content-Type" => "application/json" }

          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body.dig("error", "message")).to eq("request body must be valid JSON")
        end
      end

      response "422", "Invalid word list" do
        schema "$ref" => "#/components/schemas/Error"
        example "application/json", :empty, { error: { code: "unprocessable_content", message: "word list must not be empty" } }
        example "application/json", :invalid_words, { error: { code: "unprocessable_content", message: 'invalid words: "h4ppy"' } }

        let(:words) { [ "happy", "h4ppy" ] }

        run_test! do
          expect(response.parsed_body.dig("error", "message")).to eq('invalid words: "h4ppy"')
        end
      end

      response "429", "Too many submissions from this client" do
        schema "$ref" => "#/components/schemas/Error"
        example "application/json", :rate_limited, { error: { code: "too_many_requests", message: "too many requests, retry later" } }

        before { 30.times { post "/complexity-score", params: words.to_json, headers: { "Content-Type" => "application/json" } } }

        run_test!
      end

      response "503", "Job queue is unavailable; nothing was stored" do
        schema "$ref" => "#/components/schemas/Error"
        example "application/json", :queue_unavailable, { error: { code: "service_unavailable", message: "job queue is unavailable, retry later" } }

        before { allow(ActiveJob).to receive(:perform_all_later).and_raise(RedisClient::CannotConnectError) }

        run_test! do
          expect(ScoringJob.count).to eq(0)
        end
      end
    end
  end

  path "/complexity-score/{job_id}" do
    parameter name: :job_id, in: :path, required: true, schema: { "$ref" => "#/components/schemas/JobId" }

    get "Fetch job status and result" do
      tags "Complexity score"
      operationId "getJob"
      description "Returns `pending` until a worker picks up the first word, `in_progress` while words are being scored, and `completed` with the result once every word is settled."
      produces "application/json"

      response "200", "Job status" do
        schema "$ref" => "#/components/schemas/Job"
        example "application/json", :pending, { job_id: "72f2ceea-99ef-4dd4-884c-62b8084b32aa", status: "pending" }
        example "application/json", :in_progress, { job_id: "72f2ceea-99ef-4dd4-884c-62b8084b32aa", status: "in_progress" }
        example "application/json", :completed, {
          job_id: "72f2ceea-99ef-4dd4-884c-62b8084b32aa",
          status: "completed",
          result: { happy: 3.0, water: 0.74, qwzxv: nil },
          errors: { qwzxv: "word not found" }
        }

        let(:job_id) { ScoringJob.submit!(WordList.new(words: %w[happy water qwzxv])).id }

        before do
          stub_dictionary("happy")
          stub_dictionary("water")
          stub_missing_word("qwzxv")
          job_id
          perform_enqueued_jobs
        end

        run_test! do
          expect(response.parsed_body).to include(
            "status" => "completed",
            "result" => { "happy" => 3.0, "water" => 0.74, "qwzxv" => nil },
            "errors" => { "qwzxv" => "word not found" }
          )
        end
      end

      response "404", "Job not found" do
        schema "$ref" => "#/components/schemas/Error"
        example "application/json", :not_found, { error: { code: "not_found", message: "resource not found" } }

        let(:job_id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
