require 'rdf_indexer'
require_relative 'concerns/deduplicatable'

# Performs RDF indexing of an envelope
class RdfIndexJob  < ActiveJob::Base
  include Deduplicatable

  def perform(envelope_id)
    envelope = Envelope.find(envelope_id)

    if envelope.deleted_at?
      RdfIndexer.delete(envelope)
    else
      RdfIndexer.index(envelope)
    end
  end
end
