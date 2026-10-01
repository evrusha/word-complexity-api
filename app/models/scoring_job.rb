class ScoringJob < ApplicationRecord
  class QueueUnavailable < StandardError; end

  has_many :word_scores, -> { order(:id) }, inverse_of: :scoring_job

  enum :status, %w[pending in_progress completed].index_by(&:itself), default: :pending

  def self.submit!(word_list)
    create!(word_scores: word_list.words.map { WordScore.new(word: it) }).tap do |scoring_job|
      ActiveJob.perform_all_later(scoring_job.word_scores.map { ScoreWordJob.new(it) })
    rescue RedisClient::Error
      scoring_job.delete
      raise QueueUnavailable, "job queue is unavailable, retry later"
    end
  end

  def start!
    self.class.pending.where(id:).update_all(status: :in_progress, updated_at: Time.current)
  end

  def complete_if_settled!
    with_lock do
      update!(status: :completed, completed_at: Time.current) unless completed? || word_scores.pending.exists?
    end
  end
end
