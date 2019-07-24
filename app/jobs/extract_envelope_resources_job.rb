require 'extract_envelope_resources'

# Runs the ExtractEnvelopeResources service in background
class ExtractEnvelopeResourcesJob < ActiveJob::Base
  def perform(envelope_id)
    envelope = Envelope.find(envelope_id)
    ExtractEnvelopeResources.call(envelope: envelope)
  end
end
