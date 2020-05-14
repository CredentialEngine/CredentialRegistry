require 'rdf_indexer'

# Performs RDF indexing of an envelope
class RdfIndexJob  < ActiveJob::Base
  def perform(envelope_id)
    envelope = Envelope.find(envelope_id)

    if envelope.deleted_at?
      RdfIndexer.delete(envelope)
    else
      RdfIndexer.index(envelope)
    end
  end
end
