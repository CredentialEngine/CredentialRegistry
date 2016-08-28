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

      expect(digest).to eq('+ZC5jvqQ4Tl6zgw+v/5k5MNDYGsxD9tU5YD7QQ9ldbo=')
    end

    it 'creates a new envelope transaction when created' do
      expect { create(:envelope) }.to change { EnvelopeTransaction.count }.by(1)
    end

    it 'creates a new envelope transaction when deleted' do
      envelope = create(:envelope, :deleted)

      expect(envelope.envelope_transactions.last.deleted?).to eq(true)
    end

    it 'logs the current operation inside the transaction' do
      envelope = create(:envelope)
      envelope.update_attributes(envelope_version: '1.0.0')

      expect(envelope.envelope_transactions.last.updated?).to eq(true)
    end
  end

  describe 'default_scope' do
    it 'Does not show deleted entries' do
      envelopes = [create(:envelope), create(:envelope)]
      expect(Envelope.count).to be 2

      envelopes.first.update_attribute(:deleted_at, Time.now)
      expect(Envelope.count).to be 1
    end
  end

  describe 'resource_schema_name' do
    context 'community without type' do
      let(:envelope) { create(:envelope) }

      it { expect(envelope.resource_schema_name).to eq 'learning_registry' }
    end

    context 'community with resource_type specification' do
      let(:envelope) { create(:envelope, :from_credential_registry) }
      let(:schema_name) { 'credential_registry/organization' }

      it { expect(envelope.resource_schema_name).to eq schema_name }
    end

    context 'community with resource_type specified as a string' do
      let(:cfg) { Hash['resource_type', '@type'] }
      let(:envelope) { create(:envelope) }

      it 'gets the resource_type directly from the resource property' do
        allow_any_instance_of(SchemaConfig).to receive(:config).and_return(cfg)
        allow(envelope.processed_resource).to(
          receive(:[]).with('@type').and_return('abc')
        )

        expect(envelope.resource_schema_name).to eq 'learning_registry/abc'
      end
    end

    context 'paradata' do
      let(:envelope) { create(:envelope, :paradata) }

      it { expect(envelope.resource_schema_name).to eq 'paradata' }
    end
  end
end
