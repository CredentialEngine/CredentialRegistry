require 'envelope_metadata'

RSpec.describe EnvelopeMetadata, type: :model do
  let(:envelope) do
    with_versioning do
      create(:envelope, :from_cer)
    end
  end

  before do
    with_versioning do
      PaperTrail.request.whodunnit = 'metadata-spec-user'
      envelope.update!(envelope_version: '2.0.0')
    ensure
      PaperTrail.request.whodunnit = nil
    end
  end

  it 'matches the metadata design representation' do
    payload = described_class.from_envelope(envelope).as_json

    expect(payload).to include(
      envelope_community: envelope.envelope_community_name,
      envelope_id: envelope.envelope_id,
      envelope_ceterms_ctid: envelope.envelope_ceterms_ctid,
      envelope_ctdl_type: envelope.envelope_ctdl_type,
      envelope_type: envelope.envelope_type,
      envelope_version: envelope.envelope_version,
      publisher_id: envelope.publisher_id,
      secondary_publisher_id: envelope.secondary_publisher_id,
      resource_publish_type: envelope.resource_publish_type,
      owned_by: envelope.organization&._ctid,
      published_by: envelope.publishing_organization&._ctid,
      changed: false,
      updated_at: envelope.updated_at,
      last_verified_on: envelope.last_verified_on
    )
    expect(payload.fetch(:node_headers)).to include(
      :resource_digest,
      :revision_history,
      :created_at,
      :updated_at,
      :deleted_at
    )
    expect(payload.dig(:node_headers, :revision_history).last).to include(actor: 'metadata-spec-user')
    expect(payload).not_to have_key(:decoded_resource)
    expect(payload).not_to have_key(:resource_format)
    expect(payload).not_to have_key(:resource_encoding)
  end
end
