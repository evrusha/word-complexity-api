require "rails_helper"

RSpec.describe ScoreWordJob do
  let!(:scoring_job) { ScoringJob.submit!(WordList.new(words: %w[happy water])) }
  let(:happy) { scoring_job.word_scores.first }
  let(:water) { scoring_job.word_scores.second }

  before do
    stub_dictionary("happy")
    stub_dictionary("water")
  end

  it "scores the word and marks the job as in progress" do
    described_class.perform_now(happy)

    expect(happy.reload).to have_attributes(status: "scored", score: 3.0, error: nil)
    expect(scoring_job.reload).to be_in_progress
  end

  it "completes the job once the last word is settled" do
    [ happy, water ].each { described_class.perform_now(it) }

    expect(scoring_job.reload).to have_attributes(status: "completed", completed_at: be_present)
  end

  it "marks a missing word as failed without retrying" do
    stub_missing_word("water")

    expect { described_class.perform_now(water) }.not_to have_enqueued_job(described_class)
    expect(water.reload).to have_attributes(status: "failed", score: nil, error: "word not found")
  end

  context "when the dictionary is unavailable" do
    before { stub_dictionary("water", status: 503, fixture: "not_found") }

    it "retries the word later" do
      expect { described_class.perform_now(water) }.to have_enqueued_job(described_class).with(water)
      expect(water.reload).to be_pending
    end

    it "fails the word and settles the job once the retries are exhausted" do
      described_class.perform_now(happy)
      perform_enqueued_jobs { described_class.perform_later(water) }

      expect(a_request(:get, /water/)).to have_been_made.times(3)
      expect(water.reload).to have_attributes(status: "failed", error: "dictionary responded with 503")
      expect(scoring_job.reload).to be_completed
    end
  end
end
