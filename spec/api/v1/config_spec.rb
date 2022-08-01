RSpec.describe API::V1::Config do
  let(:community) { create(:envelope_community, name: 'navy') }
  let(:token) { user.auth_token.value }
  let(:user) { create(:user) }

  describe 'GET /metadata/:community_name/config' do
    context 'unauthenticated' do
      it 'returns 401' do
        get '/metadata/ce-registry/config'
        expect_status(:unauthorized)
        expect_json('errors', ['401 Unauthorized'])
      end
    end

    context 'nonexistent community' do
      it 'returns 404' do
        get '/metadata/ce-registry/config', 'Authorization' => "Token #{token}"
        expect_status(:not_found)
        expect_json('errors', ["Couldn't find the envelope community"])
      end
    end

    context 'no config' do
      it 'falls back to default config' do
        get "/metadata/#{community.name}/config",
            'Authorization' => "Token #{token}"

        expect_status(:ok)
        expect(JSON(response.body)).to eq(
          JSON(File.read(MR.root_path.join('fixtures', 'configs', 'navy.json')))
        )
      end
    end

    context 'config exists' do
      let!(:config) do
        create(:envelope_community_config, envelope_community: community)
      end

      it 'returns config' do
        get "/metadata/#{community.name}/config",
            'Authorization' => "Token #{token}"

        expect_status(:ok)
        expect(JSON(response.body)).to eq(config.payload)
      end
    end
  end

  describe 'POST /metadata/:community_name/config' do
    context 'unauthenticated' do
      it 'returns 401' do
        post '/metadata/ce-registry/config',
             nil,
             'Authorization' => 'Token token'

        expect_status(:unauthorized)
        expect_json('errors', ['401 Unauthorized'])
      end
    end

    context 'nonexistent community' do
      it 'returns 404' do
        post '/metadata/ce-registry/config',
             nil,
             'Authorization' => "Token #{token}"

        expect_status(:not_found)
        expect_json('errors', ["Couldn't find the envelope community"])
      end
    end

    context 'existing community' do
      let(:description) { Faker::Lorem.sentence }
      let(:payload) { JSON(Faker::Json.shallow_json) }

      context 'no params' do
        it 'returns 422' do
          post "/metadata/#{community.name}/config",
               nil,
               'Authorization' => "Token #{token}"

          expect_status(:bad_request)
          expect_json('errors', ['description is missing', 'payload is missing'])
        end
      end

      context 'no description' do
        it 'returns 422' do
          post "/metadata/#{community.name}/config",
               { description: '', payload: payload },
               'Authorization' => "Token #{token}"

          expect_status(:unprocessable_entity)
          expect_json('errors', ["Description can't be blank"])
        end
      end

      context 'no payload' do
        it 'returns 422' do
          post "/metadata/#{community.name}/config",
               { description: description, payload: nil },
               'Authorization' => "Token #{token}"

          expect_status(:unprocessable_entity)
          expect_json('errors', ["Payload can't be blank"])
        end
      end

      context 'no config' do
        it 'creates config' do
          expect {
            post "/metadata/#{community.name}/config",
                 { description: description, payload: payload },
                 'Authorization' => "Token #{token}"
          }.to change { EnvelopeCommunityConfig.count }.by(1)

          expect_status(:ok)
          expect_json('description', description)
          expect_json('payload', **payload.symbolize_keys)

          config = EnvelopeCommunityConfig.last
          expect(config.description).to eq(description)
          expect(config.payload).to eq(payload)
        end
      end

      context 'config exists' do
        let!(:config) do
          create(:envelope_community_config, envelope_community: community)
        end

        it 'updates config' do
          expect {
            post "/metadata/#{community.name}/config",
                 { description: description, payload: payload },
                 'Authorization' => "Token #{token}"
          }.to change { EnvelopeCommunityConfig.count }.by(0)
          .and change { config.reload.description }.to(description)
          .and change { config.reload.payload }.to(payload)

          expect_status(:ok)
          expect_json('description', description)
          expect_json('payload', **payload.symbolize_keys)
        end
      end
    end
  end
end
