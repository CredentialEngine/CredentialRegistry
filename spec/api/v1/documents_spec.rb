describe API::V1::Documents do
  context 'GET /api/documents' do
    let!(:documents) do
      [create(:document), create(:document)]
    end

    before(:each) do
      get '/api/documents'
    end

    it 'returns a 200 OK http status code' do
      expect_status(:ok)
    end

    it 'retrieves all the documents ordered by date' do
      expect(documents.count).to eq(2)
      expect(documents.first.created_at).to be < documents.last.created_at
    end

    it 'presents the JWT fields in decoded form' do
      expect_json('0.user_envelope', resource_data: 'contents')
    end
  end

  context 'POST /api/documents' do
    context 'with valid parameters' do
      let(:publish) do
        -> { post '/api/documents', attributes_for(:document_with_id) }
      end

      it 'returns a 201 Created http status code' do
        publish.call

        expect_status(:created)
      end

      it 'creates a new document' do
        expect { publish.call }.to change { Document.count }.by(1)
      end
    end

    context 'with invalid parameters' do
      before(:each) do
        post '/api/documents', {}
      end

      it 'returns a 400 Bad Request http status code' do
        expect_status(:bad_request)
      end

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'doc_type is missing')
      end
    end

    context 'when persistence error' do
      before(:each) do
        create(:document_with_id)
        post '/api/documents',
             attributes_for(:document,
                            doc_id: 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56')
      end

      it 'returns a 422 Unprocessable Entity http status code' do
        expect_status(:unprocessable_entity)
      end

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'Doc has already been taken')
      end
    end
  end
end
