require "rails_helper"

RSpec.describe Dictionary::Profile do
  def profile_of(word) = described_class.parse(JSON.parse(file_fixture("dictionary/#{word}.json").read))

  it "counts definitions and unique synonyms and antonyms across every meaning" do
    expect(profile_of("water")).to have_attributes(definitions: 19, synonyms: 1, antonyms: 13)
  end

  it "computes the complexity rounded to two decimals" do
    expect(profile_of("water").complexity).to eq(0.74)
    expect(profile_of("happy").complexity).to eq(3.0)
  end

  it "includes synonyms and antonyms listed on individual definitions" do
    entries = [ { "meanings" => [ { "synonyms" => [ "a" ], "definitions" => [ { "synonyms" => %w[a b], "antonyms" => [ "c" ] } ] } ] } ]

    expect(described_class.parse(entries)).to have_attributes(definitions: 1, synonyms: 2, antonyms: 1)
  end

  it "ignores malformed parts of the response" do
    entries = [ "noise", { "meanings" => nil }, { "meanings" => [ "noise", { "synonyms" => [ nil, "a" ], "definitions" => [ {}, 1 ] } ] } ]

    expect(described_class.parse(entries)).to have_attributes(definitions: 1, synonyms: 1, antonyms: 0)
  end

  it "scores a word without definitions as zero" do
    expect(described_class.parse([]).complexity).to eq(0.0)
  end
end
