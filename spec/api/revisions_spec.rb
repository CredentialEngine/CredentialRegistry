describe API::V1::Revisions do
  let!(:envelope) { create(:envelope, envelope_version: '0.9.0') }

  context 'GET /:community/envelopes/:envelope_id/revisions/:revision_id' do
    before(:each) do
      with_versioned_envelope(envelope) do
        get "/learning-registry/envelopes/#{envelope.envelope_id}"\
            "/revisions/#{envelope.versions.first.id}"
      end
    end

    it { expect_status(:ok) }

    it 'retrieves the desired envelope' do
      expect_json(envelope_id: envelope.envelope_id)
      expect_json(envelope_version: '0.9.0')
    end
  end
end
