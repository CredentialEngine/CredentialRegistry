describe API::V1::Documents do
  context 'GET /api/documents' do
    let!(:documents) do
      [create(:document), create(:document)]
    end

    before(:each) { get '/api/documents' }

    it { expect_status(:ok) }

    it 'retrieves all the documents ordered by date' do
      expect_json_sizes(2)
      expect_json('0.doc_id', documents.first.doc_id)
    end

    it 'presents the JWT fields in decoded form' do
      expect_json('0.user_envelope.name', 'The Constitution at Work')
    end
  end

  context 'POST /api/documents' do
    context 'with valid parameters' do
      let(:publish) do
        -> { post '/api/documents', attributes_for(:document, :with_id) }
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
      before(:each) { post '/api/documents', {} }

      it { expect_status(:bad_request) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'doc_type is missing')
      end
    end

    context 'when persistence error' do
      before(:each) do
        create(:document, :with_id)
        post '/api/documents',
             attributes_for(:document,
                            doc_id: 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56')
      end

      it { expect_status(:unprocessable_entity) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'Doc has already been taken')
      end
    end
  end

  context 'PATCH /api/documents/:id' do
    let!(:document) { create(:document, :with_id) }

    context 'with valid parameters' do
      before(:each) do
        user_envelope = JWT.encode(attributes_for(:resource,
                                                  name: 'Updated'), nil, 'none')
        patch "/api/documents/#{document.doc_id}",
              attributes_for(:document, user_envelope: user_envelope)
      end

      it { expect_status(:no_content) }

      it 'updates the resource data inside the user envelope' do
        document.reload
        envelope = JWT.decode document.user_envelope, nil, false

        expect(envelope.first.symbolize_keys[:name]).to eq('Updated')
      end
    end

    context 'with invalid parameters' do
      before(:each) { patch '/api/documents/non-existent-doc-id', {} }

      it { expect_status(:not_found) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'Couldn\'t find Document')
      end
    end
  end

  context 'DELETE /api/documents/:id' do
    let!(:document) { create(:document) }

    context 'with valid parameters' do
      before(:each) { delete "/api/documents/#{document.doc_id}" }

      it { expect_status(:no_content) }

      it 'marks the document as deleted' do
        document.reload

        expect(document.deleted_at).not_to be_nil
      end
    end

    context 'trying to delete a non existent document' do
      before(:each) { delete '/api/documents/non-existent-doc-id' }

      it { expect_status(:not_found) }

      it 'returns the list of validation errors' do
        expect_json('errors.0', 'Couldn\'t find Document')
      end
    end
  end
end
