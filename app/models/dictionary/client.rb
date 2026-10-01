class Dictionary::Client
  def initialize(connection: self.class.connection)
    @connection = connection
  end

  def entries(word)
    response = @connection.get(ERB::Util.url_encode(word))

    case [ response.status, response.body ]
    in [ 200, Array => entries ] then entries
    in [ 200, _ ] then raise Dictionary::Unavailable, "dictionary returned an unexpected response"
    in [ 404, _ ] then raise Dictionary::WordNotFound, "word not found"
    in [ status, _ ] then raise Dictionary::Unavailable, "dictionary responded with #{status}"
    end
  rescue Faraday::TimeoutError
    raise Dictionary::Unavailable, "dictionary timed out"
  rescue Faraday::Error
    raise Dictionary::Unavailable, "dictionary request failed"
  end

  def self.connection
    @connection ||= Faraday.new(Dictionary.config.base_url) do
      it.options.open_timeout = Dictionary.config.open_timeout
      it.options.timeout = Dictionary.config.timeout
      it.response :json
    end
  end
end
