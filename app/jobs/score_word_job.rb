class ScoreWordJob < ApplicationJob
  queue_as :scoring

  retry_on Dictionary::Unavailable, wait: 5.seconds, attempts: 3 do |job, error|
    job.arguments.first.fail!(error)
  end

  def perform(word_score) = word_score.evaluate!
end
