require 'elasticsearch/model'
# require "lib/elasticsearch/persistence/repository/response/results"

ES_CLIENT = Elasticsearch::Client.new(
  host: ENV['ELASTICSEARCH_ADDRESS']
)

# Search module utility functions
module Search
  module_function

  def fields_map
    @fields_map ||= {
      key:     { type: 'string', analyzer: 'keyword' },
      full:    { type: 'string', analyzer: 'full_str' },
      partial: { type: 'string', analyzer: 'partial_str' }
    }
  end

  def multi_field(prop, keys)
    fields = keys.each_with_object(prop => { type: 'string' }) do |key, acc|
      acc[key] = fields_map[key]
      acc
    end
    { type: 'multi_field', fields: fields }
  end

  def full_str_analyzer
    {
      filter: %w(standard lowercase stop_en asciifolding),
      type: 'custom',
      tokenizer: 'standard'
    }
  end

  def partial_str_analyzer
    {
      filter: %w(standard lowercase stop_en asciifolding str_ngrams),
      type: 'custom',
      tokenizer: 'standard'
    }
  end

  def filter_settings
    {
      str_ngrams: { type: 'nGram', min_gram: 3, max_gram: 10 },
      stop_en:    { type: 'stop', stopwords: '_english_' }
    }
  end

  def analyzer_settings
    {
      full_str: full_str_analyzer,
      partial_str: partial_str_analyzer
    }
  end

  def index_settings
    {
      analysis: {
        filter: filter_settings,
        analyzer: analyzer_settings
      }
    }
  end

  # ES repository abstraction
  class Repository
    include Elasticsearch::Persistence::Repository

    client ES_CLIENT

    # index  options[:index] || :"unbounded_#{Rails.env}"

    # type :documents

    # klass ::Search::Document

    # settings index: ::Search.index_settings do
    #   mappings dynamic: 'false' do
    #     indexes :model_type,    type: 'string', index: 'not_analyzed'
    #     indexes :model_id,      type: 'string', index: 'not_analyzed'
    #     indexes :title,         **::Search.ngrams_multi_field(:title)
    #     indexes :subject,       type: 'string'
    #   end
    # end

    def index_exists?
      client.indices.exists? index: index
    rescue Faraday::ConnectionFailed
      false
    end

    # def empty_response
    #   Elasticsearch::Persistence::Repository::Response::Results.new(
    #     self, {hits: {total: 0, max_score: nil, hits:[]}}
    #   )
    # end
  end
end
