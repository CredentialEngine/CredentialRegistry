require 'elasticsearch/model'
require 'search/utils'
require 'search/schema'
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
      mappings do
        indexes :envelope_id,          type: 'string', index: 'not_analyzed'
        indexes :envelope_type,        type: 'string', index: 'not_analyzed'
        indexes :envelope_version,     type: 'string', index: 'not_analyzed'
        indexes :community,            type: 'string', index: 'not_analyzed'
        indexes :resource_schema_name, type: 'string', index: 'not_analyzed'

        indexes :_fts, **::Search.multi_field(:_fts, [:full, :partial])
      end
    end

    def index_exists?(opts = {})
      client.indices.exists? index: opts.fetch(:index, index)
    rescue Faraday::ConnectionFailed
      false
    end

    def empty_response
      Elasticsearch::Persistence::Repository::Response::Results.new(
        self, hits: { total: 0, max_score: nil, hits: [] }
      )
    end
  end
end
