class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render_error :not_found, "resource not found"
  end

  rescue_from ActionDispatch::Http::Parameters::ParseError, WordList::Malformed do |error|
    render_error :bad_request, error.message
  end

  rescue_from WordList::Invalid do |error|
    render_error :unprocessable_content, error.message
  end

  rescue_from ScoringJob::QueueUnavailable do |error|
    render_error :service_unavailable, error.message
  end

  private
    def render_error(status, message)
      render json: { error: { code: status, message: } }, status:
    end
end
