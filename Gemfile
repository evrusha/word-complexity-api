source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

gem "faraday", "~> 2.13"
gem "jbuilder", "~> 2.14"
gem "redis", "~> 5.4"
gem "sidekiq", "~> 8.0"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 8.0"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "webmock", "~> 3.25"
end
