require 'index_envelope_resource'
require_relative 'concerns/deduplicatable'

# Runs the IndexEnvelopeResource service in background
class IndexEnvelopeResourceJob < ActiveJob::Base
  include Deduplicatable

  def perform(envelope_resource_id)
    resource = EnvelopeResource.find_by(id: envelope_resource_id)
    IndexEnvelopeResource.call(resource) if resource
  end
end
