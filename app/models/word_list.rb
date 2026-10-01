class WordList < Data.define(:words)
  MAX_SIZE = 100
  MAX_WORD_LENGTH = 50
  FORMAT = /\A[a-z]+(?:[-' ][a-z]+)*\z/

  class Malformed < StandardError; end
  class Invalid < StandardError; end

  def self.parse(body)
    case JSON.parse(body)
    in [] then raise Invalid, "word list must not be empty"
    in Array => words if words.size > MAX_SIZE then raise Invalid, "word list must not exceed #{MAX_SIZE} words"
    in Array => words if words.all?(String) then new(words:)
    else raise Invalid, "request body must be a JSON array of words"
    end
  rescue JSON::ParserError
    raise Malformed, "request body must be valid JSON"
  end

  def initialize(words:)
    normalized = words.map { it.strip.squeeze(" ").downcase }.uniq
    invalid = normalized.reject { it.length <= MAX_WORD_LENGTH && it.match?(FORMAT) }
    raise Invalid, "invalid words: #{invalid.map { it.truncate(MAX_WORD_LENGTH).inspect }.join(", ")}" if invalid.any?

    super(words: normalized)
  end
end
