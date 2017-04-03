describe API::V1::Resources do
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
end
