module Search
  # ES indexed document
  class Document
    include Virtus.model

    attribute :envelope_id, String
    attribute :envelope_type, String
    attribute :envelope_version, String
    attribute :community, String

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

    private

    def attributes(envelope)
      {
        envelope_id: envelope.envelope_id,
        envelope_type: envelope.envelope_type,
        community: envelope.community_name
      }
    end
  end
end
