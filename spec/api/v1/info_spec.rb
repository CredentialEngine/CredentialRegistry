describe 'API info' do
  before(:example) do
    @envelope = create(:envelope)
    create(:envelope, :from_cer)
  end

  context 'GET /api/:community/info' do
    before(:example) { get '/api/learning-registry/info' }

    it { expect_status(:ok) }

    it 'retrieves info about the node' do
      expect_json(total_envelopes: 1)
      expect_json(backup_item: 'learning-registry-test')
    end
  end

  context 'GET /api/:community/envelopes/info' do
    before(:example) { get '/api/learning-registry/envelopes/info' }

    it { expect_status(:ok) }

    it 'retrieves info about the envelopes' do
      expect_json_keys %i(POST PUT)
    end
  end

  context 'GET /api/schemas/info' do
    before(:example) { get '/api/schemas/info' }

    it { expect_status(:ok) }

    it 'retrieves info about the schemas' do
      expect_json_keys %i(available_schemas)
    end
  end

  context 'GET /api/:community/envelopes/:id/info' do
    before(:example) do
      get "/api/learning-registry/envelopes/#{@envelope.envelope_id}/info"
    end

    it { expect_status(:ok) }

    it 'retrieves info about the envelope' do
      expect_json_keys %i(PATCH DELETE)
    end
  end
end
