if Rails.env.development?
  require "sidekiq/web"

  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_word_complexity_sidekiq"
end
