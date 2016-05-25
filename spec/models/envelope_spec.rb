require 'envelope'

describe Envelope, type: :model do
  describe 'callbacks' do
    it 'generates an envelope id if it does not exist' do
      envelope = create(:envelope, envelope_id: nil)

      expect(envelope.envelope_id.present?).to eq(true)
    end

    it 'honors the provided envelope id' do
      envelope = create(:envelope, envelope_id: '12345')

      expect(envelope.envelope_id).to eq('12345')
    end

    it 'processes the resource in JSON format' do
      envelope = create(:envelope)

      expect(envelope.decoded_resource.name).to eq('The Constitution at Work')
    end

    it 'processes the resource in XML format' do
      envelope = create(:envelope, :with_xml_resource)

      expect(envelope.decoded_resource.name).to eq('The Constitution at Work')
    end

    it 'appends the node headers with the resource digest' do
      envelope = create(:envelope)
      digest = envelope.decoded_node_headers.resource_digest

      expect(digest).to eq('AG17F7LgTfhFRqe3D24mbaBuj/OPVdTmNwp96L5J034=')
    end

    it 'creates a new envelope transaction when created' do
      expect { create(:envelope) }.to change { EnvelopeTransaction.count }.by(1)
    end

    it 'logs the current operation inside the transaction' do
      envelope = create(:envelope)
      envelope.update_attributes(envelope_version: '1.0.0')

      expect(envelope.envelope_transactions.last.updated?).to eq(true)
    end
  end
end
