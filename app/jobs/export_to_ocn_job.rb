require 'ocn_exporter'

class ExportToOCNJob < ActiveJob::Base
  def perform(envelope_id)
    envelope = Envelope.find_by(id: envelope_id)
    return unless envelope

    OCNExporter.new(envelope:).export
  end
end
