require 'extract_envelope_resources'
require_relative 'concerns/deduplicatable'

# Runs the ExtractEnvelopeResources service in background
class ExtractEnvelopeResourcesJob < ActiveJob::Base
  include Deduplicatable

  def perform(envelope_id)
    envelope = Envelope.find(envelope_id)
    ExtractEnvelopeResources.call(envelope: envelope)
  end
end
