describe API::V1::Search do
  before(:context) do
    create(:envelope_community)
    create(:envelope_community, name: 'credential_registry')
  end

  context 'GET /api/search' do
    context 'match_all' do
      before(:example) { get '/api/search' }

      it { expect_status(:ok) }
    end

    context 'fts' do
      before(:example) do
        create(:envelope)
        create(:envelope, :from_credential_registry)

        get '/api/search?fts=constitutio'
      end

      it { expect_status(:ok) }
      it { expect(json_resp.size).to be > 0 }
    end
  end

  context 'GET /api/{community}/search' do
    before(:example) { get '/api/learning-registry/search' }

    it { expect_status(:ok) }
  end

  context 'GET /api/{community}/{type}/search' do
    before(:example) { get '/api/credential-registry/organizations/search' }

    it { expect_status(:ok) }
  end
end
