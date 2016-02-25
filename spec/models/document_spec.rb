require 'document'

describe Document, type: :model do
  describe 'callbacks' do
    it 'generates a document id if it does not exist' do
      document = create(:document, doc_id: nil)

      expect(document.doc_id.present?).to eq(true)
    end

    it 'honors the provided doc id' do
      document = create(:document, doc_id: '12345')

      expect(document.doc_id).to eq('12345')
    end
  end
end
