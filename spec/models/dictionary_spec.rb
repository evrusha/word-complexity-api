require "rails_helper"

RSpec.describe Dictionary do
  it "caches the profile of a word" do
    request = stub_dictionary("happy")

    2.times { described_class.profile("happy") }

    expect(described_class.profile("happy").complexity).to eq(3.0)
    expect(request).to have_been_requested.once
  end

  it "does not cache a missing word" do
    request = stub_missing_word("qwzxv")

    2.times { expect { described_class.profile("qwzxv") }.to raise_error(Dictionary::WordNotFound) }

    expect(request).to have_been_requested.twice
  end
end
