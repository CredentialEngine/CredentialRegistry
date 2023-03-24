require 'precalculate_description_sets'

class PrecalculateDescriptionSetsJob < ActiveJob::Base
  def perform(envelope_id)
    envelope = Envelope.find_by(id: envelope_id)
    PrecalculateDescriptionSets.process(envelope) if envelope
  end
end
