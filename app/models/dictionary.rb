module Dictionary
  class Error < StandardError; end
  class WordNotFound < Error; end
  class Unavailable < Error; end

  CACHE_VERSION = 1

  def self.profile(word)
    Rails.cache.fetch([ "dictionary", CACHE_VERSION, word ], expires_in: config.cache_ttl) { Profile.parse(Client.new.entries(word)) }
  end

  def self.config = Rails.configuration.dictionary
end
