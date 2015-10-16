class TransferNounPhraseService
  def initialize(old_noun, new_noun)
    @old_noun = old_noun
    @new_noun = new_noun
  end

  def call
    ActiveRecord::Base.transaction do
      @old_noun.qualities.each do |quality|
        quality.noun_phrase = @new_noun
        quality.save(validate: false)
      end

      NounAlias.create(text: @old_noun.text, quality_noun_phrase: @new_noun)
      @old_noun.destroy!
      @new_noun.touch
      Sunspot.index! @new_noun
    end
  end

  # Transfer many noun phrases. The arguments must be
  # in the following way:
  # TransferNounPhrase.batch([old_1, new_1], [old_2, new_2])
  def self.batch(*pairs)
    pairs.each { |pair| new(QualityNounPhrase.find(pair[0]), QualityNounPhrase.find(pair[1])).call }
  end
end
