describe API::V1::Documents do
  context 'GET /api/documents' do
    it 'returns a sample text' do
      get '/api/documents'

      expect_json(text: 'Documents list')
    end
  end
end
