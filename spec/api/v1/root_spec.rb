RSpec.describe API::V1::Revisions do # rubocop:todo RSpec/SpecFilePathFormat
  before do
    create(:envelope)
    create(:envelope, :from_cer)
  end

  context 'GET' do # rubocop:todo RSpec/ContextWording
    before { get '/' }

    it { expect_status(:ok) }

    it 'retrieves api info' do
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

    it { expect_status(:ok) }

    it 'retrieves info about the node' do
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

    it { expect_status(:ok) }

    it 'retrieves the swagger.json' do
      expect_json('swagger', '2.0')
    end
  end
end
