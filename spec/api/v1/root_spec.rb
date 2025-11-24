RSpec.describe API::V1::Revisions do # rubocop:todo RSpec/SpecFilePathFormat
  before do
    ENV['AUTHENTICATION_REQUIRED'] = auth_required

    create(:envelope)
    create(:envelope, :from_cer)
  end

  after do
    ENV.delete('AUTHENTICATION_REQUIRED')
  end

  context 'with no authentication required' do
    let(:auth_required) { '' }

    context 'GET' do # rubocop:todo RSpec/ContextWording
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

    context 'GET /info' do # rubocop:todo RSpec/ContextWording
      before { get '/info' }

      it 'retrieves info about the node' do
        expect_status(:ok)

        expect_json_keys(%i[postman swagger readme docs
                            metadata_communities])

        data = JSON.parse(response.body)
        expect(data['metadata_communities'].keys).to match_array(
          %w[learning_registry ce_registry]
        )
      end
    end

    context 'GET /swagger.json' do # rubocop:todo RSpec/ContextWording
      before { get '/swagger.json' }

      it 'retrieves the swagger.json' do
        expect_status(:ok)
        expect_json('swagger', '2.0')
      end
    end
  end

  context 'with authentication required' do
    let(:auth_required) { 'true' }

    context 'GET' do # rubocop:todo RSpec/ContextWording
      before { get '/' }

      it { expect_status(:unauthorized) }
    end

    context 'GET /info' do # rubocop:todo RSpec/ContextWording
      before { get '/info' }

      it { expect_status(:unauthorized) }
    end

    context 'GET /swagger.json' do # rubocop:todo RSpec/ContextWording
      before { get '/swagger.json' }

      it 'retrieves the swagger.json' do
        expect_status(:ok)
        expect_json('swagger', '2.0')
      end
    end
  end
end
