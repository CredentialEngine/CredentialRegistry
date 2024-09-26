require 'index_envelope_resource'
require 'precalculate_description_sets_job'

# 1. Indexes each of the envelope's resources
# 2. Precalculate description sets for the envelope
class IndexEnvelopeJob < ActiveJob::Base
  def perform(envelope_id)
    envelope = Envelope.find_by(id: envelope_id)
    return unless envelope

    Parallel.each(envelope.envelope_resources.pluck(:id)) do |resource_id|
      resource = EnvelopeResource.find(resource_id)
      IndexEnvelopeResource.call(resource)
    rescue ActiveRecord::RecordNotUnique => e
      Airbrake.notify(e, resource_id: resource.resource_id)
    end

    PrecalculateDescriptionSetsJob.perform_later(envelope.id)
  end
end
