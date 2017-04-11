describe API::V1::CommunityResources do
  let!(:ec)       { create(:envelope_community, name: 'ce_registry') }
  let!(:name)     { ec.name }
  let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
  let!(:resource) { envelope.processed_resource }
  let!(:id)       { resource['@id'] }

  context 'CREATE /api/:community_name/resources' do
    before do
      post "/api/#{name}/resources", attributes_for(:envelope, :from_cer)
    end

    it 'returns a 201 Created http status code' do
      expect_status(:created)
    end

    context 'returns the newly created envelope' do
      it { expect_json_types(envelope_id: :string) }
      it { expect_json(envelope_community: 'ce_registry') }
      it { expect_json(envelope_version: '0.52.0') }
    end
  end

  context 'GET /api/:community_name/resources/:id' do
    let!(:id)       { '123-123-123' }
    let!(:resource) { jwt_encode(attributes_for(:cer_org).merge('@id': id)) }
    let!(:envelope) do
      create(:envelope, :from_cer, :with_cer_credential,
             resource: resource, envelope_community: ec)
    end

    describe 'retrieves the desired resource' do
      before do
        get "/api/#{name}/resources/#{id}"
      end

      it { expect_status(:ok) }
      it { expect_json('@id': id) }
    end

    context 'wrong community_name' do
      before do
        get "/api/learning_registry/resources/#{id}"
      end

      it { expect_status(:not_found) }
    end

    context 'invalid id' do
      before do
        get "/api/#{name}/resources/'9999INVALID'"
      end

      it { expect_status(:not_found) }
    end
  end

  # The default for example.org (testing) is set to 'ce_registry'
  # See config/envelope_communities.json
  context 'envelope_community parameter' do
    describe 'not given' do
      before do
        post '/api/resources', attributes_for(:envelope, :from_cer)
      end

      describe 'use the default' do
        it { expect_status(:created) }
      end
    end

    describe 'in envelope' do
      before do
        post '/api/resources', attributes_for(:envelope, :from_cer,
                                              envelope_community: name)
      end

      describe 'use the default' do
        it { expect_status(:created) }
      end

      describe 'don\'t match' do
        let(:name) { 'learning_registry' }
        it { expect_status(:unprocessable_entity) }
        it 'returns the correct error messsage' do
          expect_json('errors.0',
                      ':envelope_community in envelope does not match ' \
                      "the default community (#{ec.name}).")
        end
      end
    end

    describe 'in path' do
      before do
        post '/api/learning_registry/resources', attributes_for(:envelope)
      end

      it { expect_status(:created) }
    end

    describe 'in path and envelope' do
      let(:url_name) { name }
      before do
        post "/api/#{url_name}/resources",
             attributes_for(:envelope, :from_cer, envelope_community: name)
      end

      it { expect_status(:created) }

      describe 'don\'t match' do
        let(:url_name) { 'learning_registry' }
        it { expect_status(:unprocessable_entity) }
        it 'returns the correct error messsage' do
          expect_json('errors.0',
                      ':envelope_community in URL and envelope don\'t match.')
        end
      end
    end
  end
end
