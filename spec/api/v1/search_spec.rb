RSpec.describe API::V1::Search do
  let(:secured) { [false, true].sample }

  before do
    create(:envelope_community, secured: secured)
    create(:envelope_community, name: 'ce_registry', secured: secured)
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
    context 'public community' do
      let(:secured) { false }

      before do
        get '/learning-registry/search'
      end

      it { expect_status(:ok) }
    end

    context 'secured community' do
      let(:api_key) { Faker::Lorem.characters }
      let(:secured) { true }

      before do
        expect(ValidateApiKey).to receive(:call)
          .with(api_key)
          .at_least(1).times
          .and_return(api_key_validation_result)

        get '/learning-registry/search',
           'Authorization' => "Token #{api_key}"
      end

      context 'authenticated' do
        let(:api_key_validation_result) { true }

        it { expect_status(:ok) }
      end

      context 'unauthenticated' do
        let(:api_key_validation_result) { false }

        it { expect_status(:unauthorized) }
      end
    end
  end

  context 'GET /{community}/{type}/search' do
    context 'public community' do
      let(:secured) { false }

      before do
        get '/ce-registry/organizations/search'
      end

      it { expect_status(:ok) }
    end

    context 'secured community' do
      let(:api_key) { Faker::Lorem.characters }
      let(:secured) { true }

      before do
        expect(ValidateApiKey).to receive(:call)
          .with(api_key)
          .at_least(1).times
          .and_return(api_key_validation_result)

        get '/ce-registry/organizations/search',
           'Authorization' => "Token #{api_key}"
      end

      context 'authenticated' do
        let(:api_key_validation_result) { true }

        it { expect_status(:ok) }
      end

      context 'unauthenticated' do
        let(:api_key_validation_result) { false }

        it { expect_status(:unauthorized) }
      end
    end
  end
end
