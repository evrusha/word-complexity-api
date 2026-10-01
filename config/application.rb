require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module WordComplexityApi
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true

    config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"], namespace: "cache" }
    config.dictionary = config_for(:dictionary)
  end
end
