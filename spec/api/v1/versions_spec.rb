describe API::V1::Versions do
  let!(:envelope) { create(:envelope, envelope_version: '0.9.0') }

  context 'GET /api/envelopes/:envelope_id/versions/:version_id' do
    before(:each) do
      with_versioning do
        envelope.envelope_version = '1.0.1'
        envelope.save!

        get "/api/envelopes/#{envelope.envelope_id}/versions/"\
            "#{envelope.versions.last.id}"
      end
    end

    it { expect_status(:ok) }

    it 'retrieves the desired envelopes' do
      expect_json(envelope_id: envelope.envelope_id)
      expect_json(envelope_version: '0.9.0')
    end
  end
end
