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

    before(:each) do
      get "/api/#{name}/resources/#{id}"
    end

    it { expect_status(:ok) }

    it 'retrieves the desired resource' do
      expect_json('@id': id)
    end

    context 'invalid community_name' do
      before(:each) do
        get "/api/learning_registry/resources/#{id}"
      end

      it { expect_status(:not_found) }
    end

    context 'invalid id' do
      before(:each) do
        get "/api/#{name}/resources/'9999INVALID'"
      end

      it { expect_status(:not_found) }
    end
  end
end
