describe API::V1::Documents do
  context 'GET /api/documents' do
    let!(:documents) do
      [create(:document), create(:document)]
    end

    before(:each) do
      get '/api/documents'
    end

    it 'retrieves all the documents ordered by date' do
      expect(documents.count).to eq(2)
      expect(documents.first.created_at).to be < documents.last.created_at
    end

    it 'presents the JWT fields in decoded form' do
      expect_json('0.user_envelope', resource_data: 'contents')
    end
  end
end
