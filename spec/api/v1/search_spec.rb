describe API::V1::Search do
  before(:context) do
    create(:envelope_community)
    create(:envelope_community, name: 'ce_registry')
  end

  context 'GET /api/search' do
    context 'match_all' do
      before(:example) { get '/api/search' }

      it { expect_status(:ok) }
    end

    context 'fts' do
      before(:example) do
        create(:envelope)
        create(:envelope, :from_cer)

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
    before(:example) { get '/api/ce-registry/organizations/search' }

    it { expect_status(:ok) }
  end
end
