require 'search/query_builder'

module Search
  # ES indexed document
  class Document
    include Virtus.model

    attribute :id, String
    attribute :envelope_id, String
    attribute :envelope_type, String
    attribute :envelope_version, String
    attribute :community, String

    attribute :_fts, String

    attribute :resource_schema_name, String
    attribute :resource, Hash

    def self.build(envelope)
      new(**attributes(envelope))
    end

    def self.repository
      @repository ||= ::Search::Repository.new
    end

    def repository
      self.class.repository
    end

    def index!
      repository.save self
    end

    def delete!
      repository.delete self
    end

    def self.search(term, options = {})
      return repository.empty_response unless repository.index_exists?

      repository.search ::Search::QueryBuilder.new(term, options).query
    end

    def self.attributes(env)
      {
        id: env.envelope_id,
        envelope_id: env.envelope_id,
        envelope_type: env.envelope_type,
        community: env.community_name,

        _fts: fts_for(env),

        resource_schema_name: env.resource_schema_name,
        resource: { env.resource_schema_name.to_sym => env.processed_resource }
      }
    end

    def self.fts_for(envelope)
      schema = search_schema(envelope)
      return '' if schema.nil?

      res = envelope.processed_resource
      schema.fetch('fts', [])
            .map { |cfg| Array.new(cfg['weight'], res.fetch(cfg['prop'], '')) }
            .flatten.compact.join('\n')
    end

    def self.search_schema(envelope)
      Search::Schema.new(envelope.resource_schema_name).schema
    end
  end
end
