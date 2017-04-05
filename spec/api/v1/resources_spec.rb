describe API::V1::Resources do
  let!(:ec) { create(:envelope_community, name: 'ce_registry') }

  context 'CREATE /api/resources' do
    before do
      post '/api/resources', attributes_for(:envelope, :from_cer,
                                            envelope_community: ec.name)
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

  context 'GET /api/resources/:id' do
    let!(:envelope)  { create(:envelope, :from_cer, :with_cer_credential) }
    let!(:resource)  { envelope.processed_resource }
    let!(:id)        { resource['@id'] }

    before(:each) do
      get "/api/resources/#{id}"
    end

    it { expect_status(:ok) }

    it 'retrieves the desired resource' do
      expect_json('@id': id)
    end

    context 'invalid id' do
      let!(:id) { '9999INVALID' }

      it { expect_status(:not_found) }
    end
  end

  context 'PUT /api/resources/:id' do
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let!(:resource) { envelope.processed_resource }
    let!(:id)       { resource['@id'] }

    before(:each) do
      update  = jwt_encode(resource.merge('ceterms:name': 'Updated'))
      payload = attributes_for(:envelope, :from_cer, :with_cer_credential,
                               resource: update,
                               envelope_community: ec.name)
      put "/api/resources/#{id}", payload
      envelope.reload
    end

    it { expect_status(:ok) }

    it 'updates some data inside the resource' do
      expect(envelope.processed_resource['ceterms:name']).to eq('Updated')
    end
  end
end
