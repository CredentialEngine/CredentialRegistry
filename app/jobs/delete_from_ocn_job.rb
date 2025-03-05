require 'ocn_exporter'

class DeleteFromOCNJob < ActiveJob::Base # rubocop:todo Style/Documentation
  def perform(envelope_ceterms_ctid, envelope_community_id)
    envelope_community = EnvelopeCommunity.find(envelope_community_id)
    envelope = Envelope.new(envelope_ceterms_ctid:, envelope_community:)

    OCNExporter.new(envelope:).delete_from_s3
  end
end
