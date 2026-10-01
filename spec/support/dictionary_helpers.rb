module DictionaryHelpers
  def stub_dictionary(word, status: 200, fixture: word)
    stub_request(:get, "#{Dictionary.config.base_url}#{ERB::Util.url_encode(word)}")
      .to_return(status:, body: file_fixture("dictionary/#{fixture}.json").read, headers: { "Content-Type" => "application/json" })
  end

  def stub_missing_word(word) = stub_dictionary(word, status: 404, fixture: "not_found")
end
