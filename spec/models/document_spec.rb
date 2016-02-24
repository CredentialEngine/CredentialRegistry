require 'document'

describe Document, type: :model do
  describe 'callbacks' do
    let(:document) { create(:document, doc_id: nil) }

    it 'generates a document id if it does not exist' do
      expect(document.doc_id.present?).to eq(true)
    end
  end
end
