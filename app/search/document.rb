require 'search/query_builder'
require 'search/response'

module Search
  # ES indexed document
  class Document
    include Virtus.model

    attribute :id, String
    attribute :envelope_id, String
    attribute :envelope_type, String
    attribute :envelope_version, String
    attribute :community, String
    attribute :date, String

    # utility field for doing Full-text-search
    attribute :_fts, String

    # pointer for the corresponding "{community}/{type}" schema
    attribute :resource_schema_name, String

    # resource is a Hash were the 'processed_resource' object is nested inside
    # a key matching the 'resource_schema_name'. We do this to avoid collisions
    # on the resource properties mapping. E.g:
    # if we have a credential_registry Organization. Then:
    #   "resource_schema_name": "credential_registry/organization"
    #   "resource": {"credential_registry/organization": {..object goes here..}}
    attribute :resource, Hash

    def self.repository
      @repository ||= ::Search::Repository.new
    end

    def repository
      self.class.repository
    end

    # Build document instance from a Envelope model
    # Return: [Search::Document]
    def self.build(envelope)
      new(**attributes(envelope))
    end

    # Parse attributes from envelope
    # Return: [Hash] attributes hash
    def self.attributes(env)
      {
        id: env.envelope_id,
        envelope_id: env.envelope_id,
        envelope_type: env.envelope_type,
        community: env.community_name,
        date: env.updated_at.to_formatted_s(:iso8601), # last modified date

        _fts: fts_for(env),

        resource_schema_name: env.resource_schema_name,
        resource: { env.resource_schema_name.to_sym => env.processed_resource }
      }
    end

    # Build the fts utility field. It's a big string with all the props we
    # desire to do a fuzzy text search, repeated N (weight) times.
    # These fields and weigths are defined on the corresponding
    # 'community/search.json' config file.
    # I.e.: if we have `{"prop": "name", "weight": 5}`, then the property
    #       'name' will be appended 5 times.
    def self.fts_for(envelope)
      schema = search_schema(envelope)
      return '' if schema.nil?

      res = envelope.processed_resource
      schema.fetch('fts', [])
            .map { |cfg| Array.new(cfg['weight'], res.fetch(cfg['prop'], '')) }
            .flatten.compact.join('\n')
    end

    # get the search configuration schema
    def self.search_schema(envelope)
      Search::Schema.new(envelope.resource_schema_name).schema
    end

    # Search using our QueryBuilder.
    # Return: [Search::Response]
    def self.search(terms, options = {})
      return repository.empty_response unless repository.index_exists?

      query = ::Search::QueryBuilder.new(terms, options).query
      ::Search::Response.new(repository.search(query), options)
    end

    # get the processed_resource nested on the resource hash
    def processed_resource
      resource[resource_schema_name]
    end

    def index!
      repository.save self
    end

    def delete!
      repository.delete self
    end
  end
end
