json.job_id @scoring_job.id
json.status @scoring_job.status

if @scoring_job.completed?
  word_scores = @scoring_job.word_scores.to_a
  failed = word_scores.select(&:failed?)

  json.result word_scores.to_h { [ it.word, it.score ] }
  json.errors failed.to_h { [ it.word, it.error ] } if failed.any?
end
