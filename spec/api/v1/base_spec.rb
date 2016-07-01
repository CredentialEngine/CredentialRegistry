describe API::V1::Versions do
  before(:example) do
    create(:envelope)
    create(:envelope, :from_credential_registry)
  end

  context 'GET /api' do
    before(:example) { get '/api' }

    it { expect_status(:ok) }

    it 'retrieves info about the node' do
      expect_json_keys(%i(api_version total_envelopes communities postman
                          swagger))
      expect_json(communities: %w(learning-registry credential-registry))
      expect_json(total_envelopes: 2)
    end
  end

  context 'GET /api/:community' do
    before(:example) { get '/api/learning-registry' }

    it { expect_status(:ok) }

    it 'retrieves info about the node' do
      expect_json(total_envelopes: 1)
      expect_json(backup_item: 'learning-registry-test')
    end
  end
end
