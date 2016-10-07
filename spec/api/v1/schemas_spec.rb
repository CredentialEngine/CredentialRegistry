describe API::V1::Schemas do
  context 'GET /api/schemas/:schema_name' do
    before(:each) do
      get "/api/schemas/#{schema_name}"
    end

    context 'valid schema' do
      let(:schema_name) { :envelope }

      it { expect_status(:ok) }

      it 'retrieves the desired schema' do
        expect_json(description: 'MetadataRegistry data envelope')
      end

      context 'community composed names' do
        let(:schema_name) { 'ce_registry/credential' }

        it { expect_status(:ok) }
      end
    end

    context 'invalid schema' do
      let(:schema_name) { :nope }

      it { expect_status(:not_found) }
    end
  end
end
