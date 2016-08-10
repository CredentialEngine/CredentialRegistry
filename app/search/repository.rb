require 'elasticsearch/model'
require 'search/utils'
require 'search/document'

module Search
  # ES repository abstraction
  class Repository
    include Elasticsearch::Persistence::Repository

    client MetadataRegistry.elasticsearch_client

    index  options[:index] || :"metadataregistry_#{MetadataRegistry.env}"

    type :documents

    klass ::Search::Document

    settings index: ::Search.index_settings do
      # mappings dynamic: 'false' do
      #   indexes :model_type,    type: 'string', index: 'not_analyzed'
      #   indexes :model_id,      type: 'string', index: 'not_analyzed'
      #   indexes :title,         **::Search.ngrams_multi_field(:title)
      #   indexes :subject,       type: 'string'
      # end
    end

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
