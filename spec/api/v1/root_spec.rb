RSpec.describe API::V1::Revisions do # rubocop:todo RSpec/SpecFilePathFormat
  before do
    ENV['AUTHENTICATION_REQUIRED'] = auth_required
    ENV['SWAGGER_ENABLED'] = swagger_enabled

    create(:envelope)
    create(:envelope, :from_cer)
  end

  after do
    ENV.delete('AUTHENTICATION_REQUIRED')
    ENV.delete('SWAGGER_ENABLED')
  end

  context 'with no authentication required' do
    let(:auth_required) { '' }

    context 'with swagger enabled' do
      let(:swagger_enabled) { 'true' }

      context 'GET' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/' }

        it 'retrieves api info' do
          expect_status(:ok)

          expect_json_keys(%i[api_version total_envelopes info
                              metadata_communities])

          data = JSON.parse(response.body)
          expect(data['metadata_communities'].keys).to match_array(
            %w[learning_registry ce_registry]
          )

          expect_json(total_envelopes: 2)
        end
      end

      context 'GET /info' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/info' }

        it 'retrieves info about the node including swagger' do
          expect_status(:ok)

          expect_json_keys(%i[postman swagger readme docs
                              metadata_communities])

          data = JSON.parse(response.body)
          expect(data['metadata_communities'].keys).to match_array(
            %w[learning_registry ce_registry]
          )
        end
      end

      context 'GET /swagger.json' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/swagger.json' }

        it 'retrieves the swagger.json' do
          expect_status(:ok)
          expect_json('swagger', '2.0')
        end
      end
    end

    context 'with swagger disabled' do
      let(:swagger_enabled) { '' }

      context 'GET' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/' }

        it 'retrieves api info' do
          expect_status(:ok)

          expect_json_keys(%i[api_version total_envelopes info
                              metadata_communities])

          data = JSON.parse(response.body)
          expect(data['metadata_communities'].keys).to match_array(
            %w[learning_registry ce_registry]
          )

          expect_json(total_envelopes: 2)
        end
      end

      context 'GET /info' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/info' }

        it 'retrieves info about the node without swagger' do
          expect_status(:ok)

          data = JSON.parse(response.body)
          expect(data.keys).to match_array(
            %w[postman readme docs metadata_communities]
          )
          expect(data).not_to have_key('swagger')
          expect(data['metadata_communities'].keys).to match_array(
            %w[learning_registry ce_registry]
          )
        end
      end

      context 'GET /swagger.json' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/swagger.json' }

        it 'returns forbidden' do
          expect_status(:forbidden)
        end
      end
    end
  end

  context 'with authentication required' do
    let(:auth_required) { 'true' }

    context 'with swagger enabled' do
      let(:swagger_enabled) { 'true' }

      context 'GET' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/' }

        it { expect_status(:unauthorized) }
      end

      context 'GET /info' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/info' }

        it { expect_status(:unauthorized) }
      end

      context 'GET /swagger.json' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/swagger.json' }

        it 'retrieves the swagger.json when not protected by auth' do
          expect_status(:ok)
          expect_json('swagger', '2.0')
        end
      end
    end

    context 'with swagger disabled' do
      let(:swagger_enabled) { '' }

      context 'GET' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/' }

        it { expect_status(:unauthorized) }
      end

      context 'GET /info' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/info' }

        it { expect_status(:unauthorized) }
      end

      context 'GET /swagger.json' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        before { get '/swagger.json' }

        it 'returns forbidden due to swagger being disabled' do
          expect_status(:forbidden)
        end
      end
    end
  end
end
