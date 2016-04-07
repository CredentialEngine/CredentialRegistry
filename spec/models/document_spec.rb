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

    it 'processes the user envelope in JSON format' do
      document = create(:document)
      processed_envelope = document.processed_envelope.symbolize_keys

      expect(processed_envelope[:name]).to eq('The Constitution at Work')
    end

    it 'processes the user envelope in XML format' do
      document = create(:document, :with_xml_envelope)
      processed_envelope = document.processed_envelope.symbolize_keys

      expect(processed_envelope[:name]).to eq('The Constitution at Work')
    end

    it 'appends the node headers with the user envelope digest' do
      document = create(:document)
      digest = document.decoded_node_headers.user_envelope_digest

      expect(digest).to eq('H+hKhZt7xuSOyNGx6XHsdAOYIUh7hUP0k2ngmhv6tHw=')
    end
  end
end
