require 'index_envelope_resource'

# Runs the IndexEnvelopeResource service in background
class IndexEnvelopeResourceJob < ActiveJob::Base
  def perform(envelope_resource_id)
    resource = EnvelopeResource.find(envelope_resource_id)
    IndexEnvelopeResource.call(resource)
  end
end
