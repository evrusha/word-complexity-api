class Dictionary::Profile < Data.define(:definitions, :synonyms, :antonyms)
  def self.parse(entries)
    meanings = nested(entries, "meanings")
    senses = nested(meanings, "definitions")
    count = ->(key) { (meanings + senses).flat_map { Array(it[key]) }.grep(String).uniq.size }

    new(definitions: senses.size, synonyms: count["synonyms"], antonyms: count["antonyms"])
  end

  def self.nested(records, key) = records.grep(Hash).flat_map { Array(it[key]) }.grep(Hash)

  def complexity = definitions.zero? ? 0.0 : (synonyms + antonyms).fdiv(definitions).round(2)
end
