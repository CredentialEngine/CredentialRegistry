RSpec.describe API::V1::Search do
  let(:secured) { [false, true].sample }

  before do
    create(:envelope_community, secured_search: secured)
    create(:envelope_community, name: 'ce_registry', secured_search: secured)
  end

  context 'GET /search' do # rubocop:todo RSpec/ContextWording
    context 'match_all' do # rubocop:todo RSpec/ContextWording
      let!(:full_envelope) { create(:envelope, :from_cer) }
      let!(:provisional_envelope) { create(:envelope, :provisional) }

      before do
        get "/search?provisional=#{provisional}"
      end

      context 'with provisional=exclude' do # rubocop:todo RSpec/NestedGroups
        let(:provisional) { 'exclude' }

        it 'returns full matches only' do
          expect_status(:ok)
          expect(json_resp.size).to eq(1)
          expect_json('0.envelope_id', full_envelope.envelope_id)
        end
      end

      context 'with provisional=include' do # rubocop:todo RSpec/NestedGroups
        let(:provisional) { 'include' }

        it 'returns all matches' do
          expect_status(:ok)
          expect(json_resp.size).to eq(2)
          expect_json('1.envelope_id', full_envelope.envelope_id)
          expect_json('0.envelope_id', provisional_envelope.envelope_id)
        end
      end

      context 'with provisional=only' do # rubocop:todo RSpec/NestedGroups
        let(:provisional) { 'only' }

        it 'returns provisional matches only' do
          expect_status(:ok)
          expect(json_resp.size).to eq(1)
          expect_json('0.envelope_id', provisional_envelope.envelope_id)
        end
      end
    end

    context 'fts' do # rubocop:todo RSpec/ContextWording
      before do
        create(:envelope)
        create(:envelope, :from_cer)

        get '/search?fts=constitutio'
      end

      it { expect_status(:ok) }
      it { expect(json_resp.size).to eq(1) }
    end

    context 'graph fts - inner (example A)' do # rubocop:todo RSpec/ContextWording
      before do
        create(:envelope, :from_cer)
        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(attributes_for(:cer_graph_competency_framework))
        )
        get '/search?fts=uqbar'
      end

      it { expect_status(:ok) }
      it { expect(json_resp.size).to eq 1 }
    end

    context 'graph fts - inner (example B)' do # rubocop:todo RSpec/ContextWording
      before do
        create(:envelope, :from_cer)
        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(attributes_for(:cer_graph_competency_framework))
        )
        get '/search?fts=orbis'
      end

      it { expect_status(:ok) }
      it { expect(json_resp.size).to eq 1 }
    end

    context 'faceted' do # rubocop:todo RSpec/ContextWording
      let(:envelope_id1) { envelope1.envelope_id } # rubocop:todo RSpec/IndexedLet
      let(:envelope_id2) { envelope2.envelope_id } # rubocop:todo RSpec/IndexedLet

      let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
        create(
          :envelope,
          envelope_ctdl_type: 'ceterms:CredentialOrganization',
          organization: create(:organization),
          publishing_organization: create(:organization)
        )
      end

      let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
        create(
          :envelope,
          :from_cer,
          envelope_ctdl_type: 'ceterms:Credential',
          organization: create(:organization),
          publishing_organization: create(:organization)
        )
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'envelope_ceterms_ctid' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:ctid1) { envelope1.envelope_ceterms_ctid } # rubocop:todo RSpec/IndexedLet
        let(:ctid2) { envelope2.envelope_ceterms_ctid } # rubocop:todo RSpec/IndexedLet

        it 'filters by CTID' do # rubocop:todo RSpec/ExampleLength
          get "/search?envelope_ceterms_ctid=#{ctid1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)
          expect_json('0.last_verified_on', envelope1.last_verified_on.to_s)

          get "/search?envelope_ceterms_ctid=#{ctid2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)

          get "/search?envelope_ceterms_ctid=#{ctid1},#{ctid2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)
          expect_json('1.envelope_id', envelope_id1)
          expect_json('0.last_verified_on', envelope1.last_verified_on.to_s)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/NestedGroups
      context 'envelope_id' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'filters by envelope_id' do # rubocop:todo RSpec/ExampleLength
          get "/search?envelope_id=#{envelope_id1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)
          expect_json('0.last_verified_on', envelope1.last_verified_on.to_s)

          get "/search?envelope_id=#{envelope_id2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)

          get "/search?envelope_id=#{envelope_id1},#{envelope_id2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)
          expect_json('1.envelope_id', envelope_id1)
          expect_json('1.last_verified_on', envelope1.last_verified_on.to_s)
        end
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'envelope_ctdl_type' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:ctdl_type1) { envelope1.envelope_ctdl_type } # rubocop:todo RSpec/IndexedLet
        let(:ctdl_type2) { envelope2.envelope_ctdl_type } # rubocop:todo RSpec/IndexedLet

        it 'filters by envelope_ctdl_type' do # rubocop:todo RSpec/ExampleLength
          get "/search?envelope_ctdl_type=#{ctdl_type1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)
          expect_json('0.last_verified_on', envelope1.last_verified_on.to_s)

          get "/search?envelope_ctdl_type=#{ctdl_type2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)

          get "/search?envelope_ctdl_type=#{ctdl_type1},#{ctdl_type2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)
          expect_json('1.envelope_id', envelope_id1)
          expect_json('1.last_verified_on', envelope1.last_verified_on.to_s)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'owned_by' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:owned_by1) { envelope1.organization._ctid } # rubocop:todo RSpec/IndexedLet
        let(:owned_by2) { envelope2.organization._ctid } # rubocop:todo RSpec/IndexedLet

        it 'filters by owned_by' do # rubocop:todo RSpec/ExampleLength
          get "/search?owned_by=#{owned_by1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)
          expect_json('0.last_verified_on', envelope1.last_verified_on.to_s)

          get "/search?owned_by=#{owned_by2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)

          get "/search?owned_by=#{owned_by1},#{owned_by2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)
          expect_json('1.envelope_id', envelope_id1)
          expect_json('1.last_verified_on', envelope1.last_verified_on.to_s)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'published_by' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/IndexedLet
        let(:published_by1) { envelope1.publishing_organization._ctid }
        # rubocop:enable RSpec/IndexedLet
        # rubocop:todo RSpec/IndexedLet
        let(:published_by2) { envelope2.publishing_organization._ctid }
        # rubocop:enable RSpec/IndexedLet

        it 'filters by published_by' do # rubocop:todo RSpec/ExampleLength
          get "/search?published_by=#{published_by1}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id1)
          expect_json('0.last_verified_on', envelope1.last_verified_on.to_s)

          get "/search?published_by=#{published_by2}"
          expect_json_sizes(1)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)

          get "/search?published_by=#{published_by1},#{published_by2}"
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelope_id2)
          expect_json('0.last_verified_on', envelope2.last_verified_on.to_s)
          expect_json('1.envelope_id', envelope_id1)
          expect_json('1.last_verified_on', envelope1.last_verified_on.to_s)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end

  context 'GET /{community}/search' do # rubocop:todo RSpec/ContextWording
    context 'public community' do # rubocop:todo RSpec/ContextWording
      let(:secured) { false }

      before do
        get '/learning-registry/search'
      end

      it { expect_status(:ok) }
    end

    context 'secured community' do # rubocop:todo RSpec/ContextWording
      let(:api_key) { Faker::Lorem.characters }
      let(:lr) { EnvelopeCommunity.find_by(name: 'learning_registry') }
      let(:secured) { true }

      before do
        # rubocop:todo RSpec/MessageSpies
        expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
          .with(api_key, lr)
          .at_least(:once)
          .and_return(api_key_validation_result)

        get '/learning-registry/search',
            'Authorization' => "Token #{api_key}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key_validation_result) { true }

        it { expect_status(:ok) }
      end

      # rubocop:todo RSpec/NestedGroups
      context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key_validation_result) { false }

        it { expect_status(:unauthorized) }
      end
    end
  end

  context 'GET /{community}/{type}/search' do # rubocop:todo RSpec/ContextWording
    context 'public community' do # rubocop:todo RSpec/ContextWording
      let(:secured) { false }

      before do
        get '/ce-registry/organizations/search'
      end

      it { expect_status(:ok) }
    end

    context 'secured community' do # rubocop:todo RSpec/ContextWording
      let(:api_key) { Faker::Lorem.characters }
      let(:cer) { EnvelopeCommunity.find_by(name: 'ce_registry') }
      let(:secured) { true }

      before do
        # rubocop:todo RSpec/MessageSpies
        expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
          .with(api_key, cer)
          .at_least(:once)
          .and_return(api_key_validation_result)

        get '/ce-registry/organizations/search',
            'Authorization' => "Token #{api_key}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key_validation_result) { true }

        it { expect_status(:ok) }
      end

      # rubocop:todo RSpec/NestedGroups
      context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key_validation_result) { false }

        it { expect_status(:unauthorized) }
      end
    end
  end
end
