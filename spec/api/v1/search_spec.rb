RSpec.describe API::V1::Search do
  let(:secured) { [false, true].sample }

  before do
    create(:envelope_community, secured_search: secured)
    create(:envelope_community, name: 'ce_registry', secured_search: secured)
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

    context 'faceted' do
      let(:envelope_id1) { envelope1.envelope_id }
      let(:envelope_id2) { envelope2.envelope_id }

      let!(:envelope1) do
        create(
          :envelope,
          envelope_ctdl_type: 'ceterms:CredentialOrganization',
          organization: create(:organization),
          publishing_organization: create(:organization)
        )
      end

      let!(:envelope2) do
        create(
          :envelope,
          :from_cer,
          envelope_ctdl_type: 'ceterms:Credential',
          organization: create(:organization),
          publishing_organization: create(:organization)
        )
      end

      context 'envelope_ceterms_ctid' do
        let(:ctid1) { envelope1.envelope_ceterms_ctid }
        let(:ctid2) { envelope2.envelope_ceterms_ctid }

        it 'filters by CTID' do
          get "/search?envelope_ceterms_ctid=#{ctid1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)

          get "/search?envelope_ceterms_ctid=#{ctid2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)

          get "/search?envelope_ceterms_ctid=#{ctid1},#{ctid2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('1.envelope_id', envelope_id1)
        end
      end

      context 'envelope_id' do
        it 'filters by envelope_id' do
          get "/search?envelope_id=#{envelope_id1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)

          get "/search?envelope_id=#{envelope_id2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)

          get "/search?envelope_id=#{envelope_id1},#{envelope_id2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('1.envelope_id', envelope_id1)
        end
      end

      context 'envelope_ctdl_type' do
        let(:ctdl_type1) { envelope1.envelope_ctdl_type }
        let(:ctdl_type2) { envelope2.envelope_ctdl_type }

        it 'filters by envelope_ctdl_type' do
          get "/search?envelope_ctdl_type=#{ctdl_type1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)

          get "/search?envelope_ctdl_type=#{ctdl_type2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)

          get "/search?envelope_ctdl_type=#{ctdl_type1},#{ctdl_type2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('1.envelope_id', envelope_id1)
        end
      end

      context 'owned_by' do
        let(:owned_by1) { envelope1.organization._ctid }
        let(:owned_by2) { envelope2.organization._ctid }

        it 'filters by owned_by' do
          get "/search?owned_by=#{owned_by1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)

          get "/search?owned_by=#{owned_by2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)

          get "/search?owned_by=#{owned_by1},#{owned_by2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('1.envelope_id', envelope_id1)
        end
      end

      context 'published_by' do
        let(:published_by1) { envelope1.publishing_organization._ctid }
        let(:published_by2) { envelope2.publishing_organization._ctid }

        it 'filters by published_by' do
          get "/search?published_by=#{published_by1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)

          get "/search?published_by=#{published_by2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)

          get "/search?published_by=#{published_by1},#{published_by2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('1.envelope_id', envelope_id1)
        end
      end
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
