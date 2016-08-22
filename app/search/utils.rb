# Search module utility functions
module Search
  # field definitions to use with multi_field
  def self.fields_map
    @fields_map ||= {
      key:     { type: 'string', analyzer: 'keyword' },
      full:    { type: 'string', analyzer: 'full_str' },
      partial: { type: 'string', analyzer: 'partial_str' }
    }
  end

  # build a multi_field property on the ES mapping.
  # E.g:
  #   Search.multi_field(name, [:partial, :full])
  #
  #   { type": 'multi_field', fields: {
  #       name:    { type: 'string'},
  #       partial: { type: 'string', analyzer: 'partial_str' },
  #       full:    { type: 'string', analyzer: 'full_str' },
  #   }}
  def self.multi_field(prop, keys)
    fields = keys.each_with_object(prop => { type: 'string' }) do |key, acc|
      acc[key] = fields_map[key]
      acc
    end
    { type: 'multi_field', fields: fields }
  end

  # Analyzer for full strings (non-partials)
  # "My dog is funny!" => [dog, funny]
  def self.full_str_analyzer
    {
      filter: %w(standard lowercase stop_en asciifolding),
      type: 'custom',
      tokenizer: 'standard'
    }
  end

  # Analyzer for partial strings using a N-grams tokenizer
  # "My dog is funny!" => [dog, fun, unn, nny, funn, unny, funny]
  def self.partial_str_analyzer
    {
      filter: %w(standard lowercase stop_en asciifolding str_ngrams),
      type: 'custom',
      tokenizer: 'standard'
    }
  end

  # Settings for the custom filters
  def self.filter_settings
    {
      str_ngrams: { type: 'nGram', min_gram: 3, max_gram: 10 },
      stop_en:    { type: 'stop', stopwords: '_english_' }
    }
  end

  # Settings for the custom analyzers
  def self.analyzer_settings
    {
      full_str: full_str_analyzer,
      partial_str: partial_str_analyzer
    }
  end

  # Build settings for the index
  def self.index_settings
    {
      analysis: {
        filter: filter_settings,
        analyzer: analyzer_settings
      }
    }
  end
end
