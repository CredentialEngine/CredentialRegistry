describe API::V1::Versions do
  let!(:document) { create(:document, doc_version: '0.9.0') }

  context 'GET /api/documents/:document_id/versions/:version_id' do
    before(:each) do
      with_versioning do
        document.doc_version = '1.0.1'
        document.save!

        get "/api/documents/#{document.doc_id}/versions/"\
            "#{document.versions.last.id}"
      end
    end

    it { expect_status(:ok) }

    it 'retrieves the desired documents' do
      expect_json(doc_id: document.doc_id)
      expect_json(doc_version: '0.9.0')
    end
  end
end
