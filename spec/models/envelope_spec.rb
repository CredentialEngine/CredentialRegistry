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

    it 'does not validate resources on mark_as_deleted!' do
      envelope = create(:envelope)
      envelope.resource = jwt_encode(name: 'inavlid resource')

      expect(envelope.valid?).to be false
      expect(envelope.mark_as_deleted!).to be_truthy
      expect(Envelope.where(envelope_id: envelope.id)).to be_empty
    end
  end

  describe 'default_scope' do
    it 'Does not show deleted entries' do
      envelopes = [create(:envelope), create(:envelope)]
      expect(Envelope.count).to eq 2

      envelopes.first.mark_as_deleted!
      expect(Envelope.count).to eq 1
    end
  end

  describe 'select_scope' do
    let!(:envelopes) { (0...3).map { create(:envelope) } }

    before { envelopes.first.mark_as_deleted! }

    it 'uses default_scope if no param is given' do
      expect(Envelope.select_scope.count).to eq 2
    end

    it 'gets all entries when include_deleted=true' do
      expect(Envelope.select_scope('true').count).to eq 3
    end

    it 'gets only deleted etries when include_deleted=only' do
      expect(Envelope.select_scope('only').count).to eq 1
    end
  end

  describe '.in_community' do
    let!(:envelope) { create(:envelope) }
    let!(:name)     { envelope.envelope_community.name }
    let!(:ec)       { create(:envelope_community, name: 'test').name }

    it 'find envelopes with community' do
      expect(Envelope.in_community(name).find(envelope.id)).to eq(envelope)
    end

    it 'find envelopes with `nil` community' do
      expect(Envelope.in_community(nil).find(envelope.id)).to eq(envelope)
    end

    it 'doesn\'t find envelopes from other communities' do
      expect do
        Envelope.in_community(ec).find(envelope.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'resource_schema_name' do
    context 'community without type' do
      let(:envelope) { create(:envelope) }

      it { expect(envelope.resource_schema_name).to eq 'learning_registry' }
    end

    context 'community with resource_type specification' do
      let(:envelope) { create(:envelope, :from_cer) }
      let(:schema_name) { 'ce_registry/organization' }

      it { expect(envelope.resource_schema_name).to eq schema_name }
    end

    context 'community with resource_type specified as a string' do
      let(:cfg) { Hash['resource_type', '@type'] }
      let(:envelope) { create(:envelope) }

      it 'gets the resource_type directly from the resource property' do
        allow_any_instance_of(EnvelopeCommunity).to(
          receive(:config).and_return(cfg)
        )
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

  describe 'CERegistryResources' do
    def build_credential(ctid)
      build(:envelope, :from_cer, resource: resource(ctid))
    end

    def resource(ctid)
      jwt_encode(
        attributes_for(:cer_cred).merge('ceterms:ctid' => ctid)
      )
    end

    it 'generates ctids' do
      expect(Envelope.generate_ctid).to match(/urn:ctid:.*/)
    end

    it 'validates uniqueness for ctid' do
      ctid = Envelope.generate_ctid

      env1 = build_credential(ctid)
      expect(env1.valid? && env1.save).to be_truthy

      # same ctid, different envelope_id => invalid
      env2 = build_credential(ctid)
      expect(env2.valid?).to be false
      expect(env2.errors.full_messages).to(
        include('Resource CTID must be unique')
      )

      # same envelope_id => valid (update)
      env1.resource = resource Envelope.generate_ctid
      expect(env1.valid?).to be true
    end
  end

  describe 'LearningRegistryResources' do
    let(:resource) do
      jwt_encode(
        attributes_for(:resource).merge(
          registry_metadata: { payload_placement: 'invalid' }
        )
      )
    end

    it 'validates registry_metadata' do
      env = build(:envelope, resource: resource)
      expect(env.valid?).to be false
      expect(env.errors.full_messages.join).to match(/registry_metadata/)
    end
  end
end
