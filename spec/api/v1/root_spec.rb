describe API::V1::Versions do
  before(:example) do
    create(:envelope)
    create(:envelope, :from_cer)
  end

  context 'GET /api' do
    before(:example) { get '/api' }

    it { expect_status(:ok) }

    it 'retrieves api info' do
      expect_json_keys(%i(api_version total_envelopes info
                          metadata_communities))

      data = JSON.parse(response.body)
      expect(data['metadata_communities'].keys).to eq(
        %w(learning_registry ce_registry)
      )

      expect_json(total_envelopes: 2)
    end
  end

  context 'GET /api/info' do
    before(:example) { get '/api/info' }

    it { expect_status(:ok) }

    it 'retrieves info about the node' do
      expect_json_keys(%i(postman swagger readme docs
                          metadata_communities))

      data = JSON.parse(response.body)
      expect(data['metadata_communities'].keys).to eq(
        %w(learning_registry ce_registry)
      )
    end
  end
end
