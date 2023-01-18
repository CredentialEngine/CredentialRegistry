require 'index_envelope_resource'
require 'precalculate_description_sets'

# 1. Indexes each of the envelope's resources
# 2. Precalculate description sets for the envelope
class IndexEnvelopeJob < ActiveJob::Base
  def perform(envelope_id)
    envelope = Envelope.find_by(id: envelope_id)
    return unless envelope

    envelope.envelope_resources.each do |resource|
      IndexEnvelopeResource.call(resource)
    end

    PrecalculateDescriptionSets.process(envelope)
  end
end
