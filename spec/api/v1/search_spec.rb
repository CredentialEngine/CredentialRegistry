describe API::V1::Search do
  before(:context) do
    create(:envelope_community)
    create(:envelope_community, name: 'ce_registry')
  end

  context 'GET /search' do
    context 'match_all' do
      before(:example) { get '/search' }

      it { expect_status(:ok) }
    end

    context 'fts' do
      before(:example) do
        create(:envelope)
        create(:envelope, :from_cer)

        get '/search?fts=constitutio'
      end

      it { expect_status(:ok) }
      it { expect(json_resp.size).to be > 0 }
    end

    context 'graph fts - inner (example A)' do
      before(:example) do
        create(:envelope, :from_cer)
        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(attributes_for(:cer_graph_competency_framework)),
          skip_validation: true
        )
        get '/search?fts=uqbar'
      end

      it { expect_status(:ok) }
      it { expect(json_resp.size).to be == 1 }
    end

    context 'graph fts - inner (example B)' do
      before(:example) do
        create(:envelope, :from_cer)
        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(attributes_for(:cer_graph_competency_framework)),
          skip_validation: true
        )
        get '/search?fts=orbis'
      end

      it { expect_status(:ok) }
      it { expect(json_resp.size).to be == 1 }
    end
  end

  context 'GET /{community}/search' do
    before(:example) { get '/learning-registry/search' }

    it { expect_status(:ok) }
  end

  context 'GET /{community}/{type}/search' do
    before(:example) { get '/ce-registry/organizations/search' }

    it { expect_status(:ok) }
  end
end
