class ComplexityScoresController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :create,
    with: -> { render_error :too_many_requests, "too many requests, retry later" }

  def create
    @scoring_job = ScoringJob.submit!(WordList.parse(request.raw_post))

    render :create, status: :accepted, location: complexity_score_url(@scoring_job)
  end

  def show
    @scoring_job = ScoringJob.find(params[:job_id])
  end
end
