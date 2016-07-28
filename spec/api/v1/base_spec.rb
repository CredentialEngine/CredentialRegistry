describe API::V1::Versions do
  before(:example) do
    create(:envelope)
    create(:envelope, :from_credential_registry)
  end

  context 'GET /api' do
    before(:example) { get '/api' }

    it { expect_status(:ok) }

    it 'retrieves info about the node' do
      expect_json_keys(%i(api_version total_envelopes info
                          metadata_communities))

      data = JSON.parse(response.body)
      expect(data['metadata_communities'].keys).to eq(
        %w(learning_registry credential_registry)
      )

      expect_json(total_envelopes: 2)
    end
  end
end
