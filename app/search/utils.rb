# Search module utility functions
module Search
  def self.fields_map
    @fields_map ||= {
      key:     { type: 'string', analyzer: 'keyword' },
      full:    { type: 'string', analyzer: 'full_str' },
      partial: { type: 'string', analyzer: 'partial_str' }
    }
  end

  def self.multi_field(prop, keys)
    fields = keys.each_with_object(prop => { type: 'string' }) do |key, acc|
      acc[key] = fields_map[key]
      acc
    end
    { type: 'multi_field', fields: fields }
  end

  def self.full_str_analyzer
    {
      filter: %w(standard lowercase stop_en asciifolding),
      type: 'custom',
      tokenizer: 'standard'
    }
  end

  def self.partial_str_analyzer
    {
      filter: %w(standard lowercase stop_en asciifolding str_ngrams),
      type: 'custom',
      tokenizer: 'standard'
    }
  end

  def self.filter_settings
    {
      str_ngrams: { type: 'nGram', min_gram: 3, max_gram: 10 },
      stop_en:    { type: 'stop', stopwords: '_english_' }
    }
  end

  def self.analyzer_settings
    {
      full_str: full_str_analyzer,
      partial_str: partial_str_analyzer
    }
  end

  def self.index_settings
    {
      analysis: {
        filter: filter_settings,
        analyzer: analyzer_settings
      }
    }
  end
end
