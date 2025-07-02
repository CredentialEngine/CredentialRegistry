RSpec.describe API::V1::Config do
  let(:community) { create(:envelope_community, name: 'navy') }
  let(:token) { user.auth_token.value }
  let(:user) { create(:user, :admin_account) }

  describe 'GET /metadata/:community_name/config' do
    context 'unauthenticated' do # rubocop:todo RSpec/ContextWording
      it 'returns 401' do
        get '/metadata/ce-registry/config'
        expect_status(:unauthorized)
        expect_json('errors', ['Invalid token'])
      end
    end

    context 'nonexistent community' do # rubocop:todo RSpec/ContextWording
      it 'returns 404' do
        get '/metadata/ce-registry/config', 'Authorization' => "Token #{token}"
        expect_status(:not_found)
        expect_json('errors', ["Couldn't find the envelope community"])
      end
    end

    context 'no config' do # rubocop:todo RSpec/ContextWording
      it 'falls back to default config' do
        get "/metadata/#{community.name}/config",
            'Authorization' => "Token #{token}"

        expect_status(:ok)
        expect(JSON(response.body)).to eq(
          JSON(File.read(MR.root_path.join('fixtures', 'configs', 'navy.json')))
        )
      end
    end

    context 'config exists' do # rubocop:todo RSpec/ContextWording
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
    context 'unauthenticated' do # rubocop:todo RSpec/ContextWording
      it 'returns 401' do
        post '/metadata/ce-registry/config',
             nil,
             'Authorization' => 'Token token'

        expect_status(:unauthorized)
        expect_json('errors', ['Invalid token'])
      end
    end

    context 'nonexistent community' do # rubocop:todo RSpec/ContextWording
      it 'returns 404' do
        post '/metadata/ce-registry/config',
             nil,
             'Authorization' => "Token #{token}"

        expect_status(:not_found)
        expect_json('errors', ["Couldn't find the envelope community"])
      end
    end

    context 'existing community' do # rubocop:todo RSpec/ContextWording
      let(:description) { Faker::Lorem.sentence }
      let(:payload) { JSON(Faker::Json.shallow_json) }

      # rubocop:todo RSpec/NestedGroups
      context 'no params' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 422' do
          post "/metadata/#{community.name}/config",
               nil,
               'Authorization' => "Token #{token}"

          expect_status(:bad_request)
          expect_json('errors', ['description is missing', 'payload is missing'])
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'no description' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 422' do
          post "/metadata/#{community.name}/config",
               { description: '', payload: payload },
               'Authorization' => "Token #{token}"

          expect_status(:unprocessable_entity)
          expect_json('errors', ["Description can't be blank"])
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'no payload' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 422' do
          post "/metadata/#{community.name}/config",
               { description: description, payload: nil },
               'Authorization' => "Token #{token}"

          expect_status(:unprocessable_entity)
          expect_json('errors', ["Payload can't be blank"])
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'no config' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'creates config' do # rubocop:todo RSpec/ExampleLength
          expect do
            post "/metadata/#{community.name}/config",
                 { description: description, payload: payload },
                 'Authorization' => "Token #{token}"
          end.to change(EnvelopeCommunityConfig, :count).by(1)

          expect_status(:ok)
          expect_json('description', description)
          expect_json('payload', **payload.symbolize_keys)

          config = EnvelopeCommunityConfig.last
          expect(config.description).to eq(description)
          expect(config.payload).to eq(payload)
        end
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'config exists' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let!(:config) do
          create(:envelope_community_config, envelope_community: community)
        end

        it 'updates config' do # rubocop:todo RSpec/ExampleLength
          expect do
            post "/metadata/#{community.name}/config",
                 { description: description, payload: payload },
                 'Authorization' => "Token #{token}"
          end.to change(EnvelopeCommunityConfig, :count).by(0) # rubocop:todo RSpec/ChangeByZero
                                                        .and change {
                                                               config.reload.description
                                                             }.to(description)
                                                              .and change {
                                                                     config.reload.payload
                                                                   }.to(payload)

          expect_status(:ok)
          expect_json('description', description)
          expect_json('payload', **payload.symbolize_keys)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end
end
