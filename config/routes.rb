Rails.application.routes.draw do
  resources :complexity_scores, path: "complexity-score", param: :job_id, only: %i[create show], defaults: { format: :json }

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check
end
