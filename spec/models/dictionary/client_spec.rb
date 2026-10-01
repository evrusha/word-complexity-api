require "rails_helper"

RSpec.describe Dictionary::Client do
  subject(:client) { described_class.new }

  it "returns the parsed entries" do
    stub_dictionary("water")

    expect(client.entries("water")).to contain_exactly(include("word" => "water"), include("word" => "water"))
  end

  it "raises WordNotFound for an unknown word" do
    stub_missing_word("qwzxv")

    expect { client.entries("qwzxv") }.to raise_error(Dictionary::WordNotFound, "word not found")
  end

  it "raises Unavailable on an upstream error" do
    stub_request(:get, /dictionaryapi/).to_return(status: 522, body: "error code: 522")

    expect { client.entries("water") }.to raise_error(Dictionary::Unavailable, "dictionary responded with 522")
  end

  it "raises Unavailable on a timeout" do
    stub_request(:get, /dictionaryapi/).to_raise(Net::ReadTimeout)

    expect { client.entries("water") }.to raise_error(Dictionary::Unavailable, "dictionary timed out")
  end

  it "raises Unavailable when the connection fails" do
    stub_request(:get, /dictionaryapi/).to_raise(Faraday::ConnectionFailed.new("Failed to open TCP connection"))

    expect { client.entries("water") }.to raise_error(Dictionary::Unavailable, "dictionary request failed")
  end

  {
    "a JSON object" => [ { title: "Unexpected" }.to_json, "application/json" ],
    "a non-JSON body" => [ "<html>maintenance</html>", "text/html" ]
  }.each do |description, (body, content_type)|
    it "raises Unavailable on #{description}" do
      stub_request(:get, /dictionaryapi/).to_return(status: 200, body:, headers: { "Content-Type" => content_type })

      expect { client.entries("water") }.to raise_error(Dictionary::Unavailable, "dictionary returned an unexpected response")
    end
  end

  it "escapes the word in the request path" do
    request = stub_request(:get, "#{Dictionary.config.base_url}ice%20cream")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    client.entries("ice cream")

    expect(request).to have_been_requested
  end
end
