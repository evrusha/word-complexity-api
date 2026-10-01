class WordScore < ApplicationRecord
  belongs_to :scoring_job

  enum :status, %w[pending scored failed].index_by(&:itself), default: :pending

  def evaluate!
    scoring_job.start!
    settle!(status: :scored, score: Dictionary.profile(word).complexity)
  rescue Dictionary::WordNotFound => error
    fail!(error)
  end

  def fail!(error) = settle!(status: :failed, error: error.message)

  private
    def settle!(**attributes)
      update!(attributes)
      scoring_job.complete_if_settled!
    end
end
