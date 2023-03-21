require 'extract_envelope_resources'
require 'index_envelope_job'
require 'precalculate_description_sets_job'

# Runs the ExtractEnvelopeResources service in background
class ExtractEnvelopeResourcesJob < ActiveJob::Base
  def perform(envelope_id)
    envelope = Envelope.find(envelope_id)
    ExtractEnvelopeResources.call(envelope:)
    IndexEnvelopeJob.perform_later(envelope_id)
  end
end
