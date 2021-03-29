require 'envelope'

RSpec.describe Envelope, type: :model do
  describe 'validation' do
    it 'validates uniqueness of ctid' do
      envelope1 = create(:envelope, :from_cer)
      envelope2 = create(:envelope, :from_cer)
      envelope2.envelope_ceterms_ctid = envelope1.envelope_ceterms_ctid

      expect {
        envelope2.save(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)

      envelope2.envelope_community = create(:envelope_community, name: 'navy')

      expect {
        envelope2.save(validate: false)
      }.not_to raise_error
    end
  end

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

    it 'processes the ctid for cer envelopes' do
      envelope = create(:envelope, :from_cer)

      ctid = envelope.processed_resource['@id'].split('/').last
      expect(envelope.envelope_ceterms_ctid).to eq(ctid)
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

    it 'schedules an indexing task when created' do
      allow(NotifyGremlinIndexer).to receive(:index_one)
      envelope = create(:envelope)
      expect(NotifyGremlinIndexer).to have_received(:index_one).with(envelope.id)
    end

    it 'schedules an indexing task when updated' do
      envelope = create(:envelope)
      allow(NotifyGremlinIndexer).to receive(:index_one)
      envelope.updated_at = Time.now
      envelope.save!(skip_validation: true)
      expect(NotifyGremlinIndexer).to have_received(:index_one).with(envelope.id)
    end

    it 'schedules a delete task when deleted' do
      envelope = create(:envelope)
      allow(NotifyGremlinIndexer).to receive(:delete_one)
      envelope.mark_as_deleted!
      expect(NotifyGremlinIndexer).to have_received(:delete_one).with(envelope.id)
    end

    it 'logs the current operation inside the transaction' do
      envelope = create(:envelope)
      envelope.update(envelope_version: '1.0.0')

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

  describe '.by_resource_id' do
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let!(:id)       { envelope.processed_resource['@id'] }

    it 'find the correct envelope' do
      expect(Envelope.by_resource_id(id)).to eq(envelope)
    end

    describe 'doesn\'t find envelopes with invalid ID' do
      let!(:id) { '9999INVALID' }
      it { expect(Envelope.by_resource_id(id)).to be_nil }
    end
  end

  describe '.with_graph' do
    let!(:envelope) do
      create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true)
    end
    let!(:envelope_with_no_graph) { create(:envelope) }
    context 'finds an envelope with a graph' do
      it 'find the correct envelope' do
        expect(Envelope.count).to eq(2)
        expect(Envelope.with_graph.count).to eq(1)
        expect(Envelope.with_graph.first).to eq(envelope)
      end
    end
  end

  describe '.community_resource' do
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let(:ec_name) { envelope.envelope_community.name }

    context 'URL ID' do
      let(:id) { envelope.processed_resource['@id'] }
      it 'find the correct envelope' do
        expect(Envelope.community_resource(ec_name, id)).to eq(envelope)
      end
    end

    context '(prefixed) URL ID' do
      let(:id) { envelope.processed_resource['@id'].split('/').last }
      it 'find the correct envelope' do
        expect(Envelope.community_resource(ec_name, id)).to eq(envelope)
      end
    end

    context '\'regular\' ID' do
      let(:id) { 'ctid:id-312313' }
      let!(:old_envelope) do
        res = envelope.processed_resource.merge('@id' => id,
                                                'ceterms:ctid' => id)
        create(:envelope, :from_cer, :with_cer_credential,
               resource: jwt_encode(res),
               envelope_community: envelope.envelope_community)
      end

      it 'find the correct envelope' do
        expect(Envelope.community_resource(ec_name, id)).to eq(old_envelope)
      end
    end

    describe 'doesn\'t find envelopes with invalid ID' do
      let!(:id) { '9999INVALID' }
      it { expect(Envelope.community_resource(ec_name, id)).to be_nil }
    end
  end

  describe '.resource_schema_name' do
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

  describe '.processed_resource_graph' do
    let(:envelope) { create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true) }
    let(:graph) { envelope.processed_resource['@graph'] }

    it 'is the graph extracted from processed_resource' do
      expect(envelope.processed_resource_graph).to eq(graph)
    end
  end

  describe '.inner_resource_from_graph' do
    let(:envelope) { create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true) }
    let(:graph) { envelope.processed_resource['@graph'] }
    let(:uqbar) { graph.find { |obj| obj.try(:[], 'ceasn:competencyText').try(:[], 'en-us') == 'Uqbar' } }
    let(:uqbar_from_inner_resource) { envelope.inner_resource_from_graph(uqbar['ceterms:ctid']) }

    it 'is extracts an inner resource from the graph, adding the context property' do
      expect(uqbar).not_to have_key('@context')
      uqbar_plus_context = uqbar.merge('@context' => envelope.processed_resource['@context'])
      expect(uqbar_from_inner_resource).to eq(uqbar_plus_context)
    end
  end

  describe '.by_top_level_object_id' do
    let(:envelope) { create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true) }
    let(:id) { envelope.processed_resource['@id'] }
    let(:graph) { envelope.processed_resource['@graph'] }
    let(:uqbar) { graph.find { |obj| obj.try(:[], 'ceasn:competencyText').try(:[], 'en-us') == 'Uqbar' } }
    let(:bnode) { graph.find { |obj| obj['@id'].start_with?('_:') } }

    it 'finds an envelope by the top level id' do
      expect(Envelope.by_top_level_object_id(envelope.processed_resource['ceterms:ctid'])).to eq(envelope)
    end

    it 'finds an envelope by an inner object id' do
      expect(Envelope.by_top_level_object_id(uqbar['ceterms:ctid'])).to eq(envelope)
    end

    it "doesn't find envelopes for an id that doesn't exist" do
      expect(Envelope.by_top_level_object_id('invalid')).to be_nil
    end

    it "doesn't find envelopes for a bnode id" do
      expect(Envelope.by_top_level_object_id(bnode['ceterms:ctid'])).to be_nil
    end
  end

  describe '.top_level_object_ids' do
    let(:envelope) { create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true) }
    let(:id) { envelope.processed_resource['ceterms:ctid'] }
    let(:graph) { envelope.processed_resource['@graph'] }

    it 'adds the primary object ctid' do
      expect(envelope.top_level_object_ids).to include(id)
    end

    it 'adds top level object ctids' do
      expected_ids = graph
                     .select { |obj| obj['@id'].start_with?('http') }
                     .map { |obj| obj['ceterms:ctid'] }
      expect(expected_ids).not_to be_empty # Sanity check
      expect(envelope.top_level_object_ids).to contain_exactly(*expected_ids)
    end

    it 'does not add bnode ctids' do
      bnodes = graph
               .select { |obj| obj['@id'].start_with?('_') }
               .map { |obj| obj['@id'] }
      expect(bnodes).not_to be_empty # Sanity check
      expect(envelope.top_level_object_ids).not_to include(*bnodes)
    end
  end

  describe 'CERegistryResources' do
    def build_credential(ctid)
      build(:envelope, :from_cer, resource: resource(ctid))
    end

    def resource(ctid)
      jwt_encode(
        attributes_for(:cer_cred).merge(
          'ceterms:ctid' => ctid,
          '@id' => "http://credentialengineregistry.org/resources/#{ctid}"
        )
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

  describe '.mark_as_deleted!' do
    let(:envelope) { create(:envelope, :from_cer) }

    before do
      create(:indexed_envelope_resource, envelope: envelope)
    end

    context 'hard' do
      it 'deleted indexed resources' do
        expect {
          envelope.mark_as_deleted!(true)
        }.to change { envelope.reload.deleted_at }.from(nil)
        .and change { envelope.reload.purged_at }.from(nil)
        .and change { IndexedEnvelopeResource.count }.by(-1)
      end
    end

    context 'soft' do
      it 'deleted indexed resources' do
        expect {
          envelope.mark_as_deleted!
        }.to change { envelope.reload.deleted_at }.from(nil)
        .and not_change { envelope.reload.purged_at }
        .and change { IndexedEnvelopeResource.count }.by(-1)
      end
    end
  end
end
