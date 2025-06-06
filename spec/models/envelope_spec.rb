require 'envelope'

RSpec.describe Envelope, type: :model do
  describe 'validation' do
    it 'validates uniqueness of ctid' do
      envelope1 = create(:envelope, :from_cer)
      envelope2 = create(:envelope, :from_cer)
      envelope2.envelope_ceterms_ctid = envelope1.envelope_ceterms_ctid

      expect do
        envelope2.save(validate: false)
      end.to raise_error(ActiveRecord::RecordNotUnique)

      envelope2.envelope_community = create(:envelope_community, name: 'navy')

      expect do
        envelope2.save(validate: false)
      end.not_to raise_error
    end
  end

  describe 'callbacks' do
    it 'generates an envelope id if it does not exist' do
      envelope = create(:envelope, envelope_id: nil)

      expect(envelope.envelope_id.present?).to be(true)
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

      expect(digest).to eq(Digest::SHA256.base64digest(envelope.resource))
    end

    it 'creates a new envelope transaction when created' do
      expect { create(:envelope) }.to change(EnvelopeTransaction, :count).by(1)
    end

    it 'creates a new envelope transaction when deleted' do
      envelope = create(:envelope, :deleted)

      expect(envelope.envelope_transactions.last.deleted?).to be(true)
    end

    it 'logs the current operation inside the transaction' do
      envelope = create(:envelope)
      envelope.update(envelope_version: '1.0.0')

      expect(envelope.envelope_transactions.last.updated?).to be(true)
    end

    it 'does not validate resources on mark_as_deleted!' do
      envelope = create(:envelope)
      envelope.resource = jwt_encode({ name: 'inavlid resource' })

      expect(envelope.valid?).to be false
      expect(envelope.mark_as_deleted!).to be_truthy
      expect(described_class.where(envelope_id: envelope.id)).to be_empty
    end

    it 'updates `last_verified_on` when envelope changes' do # rubocop:todo RSpec/ExampleLength
      envelope = build(:envelope)
      initial_date = Date.yesterday
      updated_date = Date.tomorrow

      travel_to initial_date do
        expect do
          envelope.save!
        end.to change { envelope.last_verified_on }.to(initial_date)
      end

      travel_to updated_date do
        expect do
          envelope.save!
        end.not_to change { envelope.reload.last_verified_on }

        expect do
          envelope.update!(envelope_version: '2.0.0')
        end.to change { envelope.reload.last_verified_on }.to(updated_date)
      end
    end
  end

  describe 'select_scope' do
    let!(:envelopes) { (0...3).map { create(:envelope) } }

    before { envelopes.first.mark_as_deleted! }

    it 'uses default_scope if no param is given' do
      expect(described_class.select_scope.count).to eq 2
    end

    it 'gets all entries when include_deleted=true' do
      expect(described_class.select_scope('true').count).to eq 3
    end

    it 'gets only deleted etries when include_deleted=only' do
      expect(described_class.select_scope('only').count).to eq 1
    end
  end

  describe '.in_community' do
    let!(:envelope) { create(:envelope) }
    let!(:name)     { envelope.envelope_community.name }
    let!(:ec)       { create(:envelope_community, name: 'test').name }

    it 'find envelopes with community' do
      expect(described_class.in_community(name).find(envelope.id)).to eq(envelope)
    end

    it 'find envelopes with `nil` community' do
      expect(described_class.in_community(nil).find(envelope.id)).to eq(envelope)
    end

    it 'doesn\'t find envelopes from other communities' do
      expect do
        described_class.in_community(ec).find(envelope.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.by_resource_id' do
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let!(:id)       { envelope.processed_resource['@id'] }

    it 'find the correct envelope' do
      expect(described_class.by_resource_id(id)).to eq(envelope)
    end

    describe 'doesn\'t find envelopes with invalid ID' do
      let!(:id) { '9999INVALID' }

      it { expect(described_class.by_resource_id(id)).to be_nil }
    end
  end

  describe '.with_graph' do
    let!(:envelope) do
      create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true)
    end
    let!(:envelope_with_no_graph) { create(:envelope) } # rubocop:todo RSpec/LetSetup

    context 'finds an envelope with a graph' do # rubocop:todo RSpec/ContextWording
      it 'find the correct envelope' do
        expect(described_class.count).to eq(2)
        expect(described_class.with_graph.count).to eq(1)
        expect(described_class.with_graph.first).to eq(envelope)
      end
    end
  end

  describe '.community_resource' do
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let(:ec_name) { envelope.envelope_community.name }

    context 'URL ID' do # rubocop:todo RSpec/ContextWording
      let(:id) { envelope.processed_resource['@id'] }

      it 'find the correct envelope' do
        expect(described_class.community_resource(ec_name, id)).to eq(envelope)
      end
    end

    context '(prefixed) URL ID' do # rubocop:todo RSpec/ContextWording
      let(:id) { envelope.processed_resource['@id'].split('/').last }

      it 'find the correct envelope' do
        expect(described_class.community_resource(ec_name, id)).to eq(envelope)
      end
    end

    context '\'regular\' ID' do # rubocop:todo RSpec/ContextWording
      let(:id) { 'ctid:id-312313' }
      let!(:old_envelope) do
        res = envelope.processed_resource.merge('@id' => id,
                                                'ceterms:ctid' => id)
        create(:envelope, :from_cer, :with_cer_credential,
               resource: jwt_encode(res),
               envelope_community: envelope.envelope_community)
      end

      it 'find the correct envelope' do
        expect(described_class.community_resource(ec_name, id)).to eq(old_envelope)
      end
    end

    describe 'doesn\'t find envelopes with invalid ID' do
      let!(:id) { '9999INVALID' }

      it { expect(described_class.community_resource(ec_name, id)).to be_nil }
    end
  end

  describe '.resource_schema_name' do
    context 'community without type' do # rubocop:todo RSpec/ContextWording
      let(:envelope) { create(:envelope) }

      it { expect(envelope.resource_schema_name).to eq 'learning_registry' }
    end

    context 'community with resource_type specification' do # rubocop:todo RSpec/ContextWording
      let(:envelope) { create(:envelope, :from_cer) }
      let(:schema_name) { 'ce_registry/organization' }

      it { expect(envelope.resource_schema_name).to eq schema_name }
    end

    # rubocop:todo RSpec/ContextWording
    context 'community with resource_type specified as a string' do
      # rubocop:enable RSpec/ContextWording
      let(:cfg) { { 'resource_type' => '@type' } }
      let(:envelope) { create(:envelope) }

      it 'gets the resource_type directly from the resource property' do
        allow_any_instance_of(EnvelopeCommunity).to( # rubocop:todo RSpec/AnyInstance
          receive(:config).and_return(cfg)
        )
        allow(envelope.processed_resource).to(
          receive(:[]).with('@type').and_return('abc')
        )

        expect(envelope.resource_schema_name).to eq 'learning_registry/abc'
      end
    end

    context 'paradata' do # rubocop:todo RSpec/ContextWording
      let(:envelope) { create(:envelope, :paradata) }

      it { expect(envelope.resource_schema_name).to eq 'paradata' }
    end
  end

  describe '.processed_resource_graph' do
    let(:envelope) do
      create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true)
    end
    let(:graph) { envelope.processed_resource['@graph'] }

    it 'is the graph extracted from processed_resource' do
      expect(envelope.processed_resource_graph).to eq(graph)
    end
  end

  describe '.inner_resource_from_graph' do
    let(:envelope) do
      create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true)
    end
    let(:graph) { envelope.processed_resource['@graph'] }
    let(:uqbar) do
      graph.find do |obj|
        obj.try(:[], 'ceasn:competencyText').try(:[], 'en-us') == 'Uqbar'
      end
    end
    let(:uqbar_from_inner_resource) { envelope.inner_resource_from_graph(uqbar['ceterms:ctid']) }

    it 'is extracts an inner resource from the graph, adding the context property' do
      expect(uqbar).not_to have_key('@context')
      uqbar_plus_context = uqbar.merge('@context' => envelope.processed_resource['@context'])
      expect(uqbar_from_inner_resource).to eq(uqbar_plus_context)
    end
  end

  describe '.by_top_level_object_id' do
    let(:envelope) do
      create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true)
    end
    let(:id) { envelope.processed_resource['@id'] }
    let(:graph) { envelope.processed_resource['@graph'] }
    let(:uqbar) do
      graph.find do |obj|
        obj.try(:[], 'ceasn:competencyText').try(:[], 'en-us') == 'Uqbar'
      end
    end
    let(:bnode) { graph.find { |obj| obj['@id'].start_with?('_:') } }

    it 'finds an envelope by the top level id' do
      # rubocop:todo Layout/LineLength
      expect(described_class.by_top_level_object_id(envelope.processed_resource['ceterms:ctid'])).to eq(envelope)
      # rubocop:enable Layout/LineLength
    end

    it 'finds an envelope by an inner object id' do
      expect(described_class.by_top_level_object_id(uqbar['ceterms:ctid'])).to eq(envelope)
    end

    it "doesn't find envelopes for an id that doesn't exist" do
      expect(described_class.by_top_level_object_id('invalid')).to be_nil
    end

    it "doesn't find envelopes for a bnode id" do
      expect(described_class.by_top_level_object_id(bnode['ceterms:ctid'])).to be_nil
    end
  end

  describe '.top_level_object_ids' do
    let(:envelope) do
      create(:envelope, :from_cer, :with_graph_competency_framework, skip_validation: true)
    end
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
      expect(envelope.top_level_object_ids).to match_array(expected_ids)
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
      expect(described_class.generate_ctid).to match(/urn:ctid:.*/)
    end

    it 'validates uniqueness for ctid' do # rubocop:todo RSpec/MultipleExpectations
      ctid = described_class.generate_ctid

      env1 = build_credential(ctid)
      expect(env1.valid? && env1.save).to be_truthy

      # same ctid, different envelope_id => invalid
      env2 = build_credential(ctid)
      expect(env2.valid?).to be false
      expect(env2.errors.full_messages).to(
        include('Resource CTID must be unique')
      )

      # same envelope_id => valid (update)
      env1.resource = resource described_class.generate_ctid
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

    context 'hard' do # rubocop:todo RSpec/ContextWording
      it 'deleted indexed resources' do
        expect do
          envelope.mark_as_deleted!
        end.to change { envelope.reload.deleted_at }.from(nil)
                                                    .and change(IndexedEnvelopeResource,
                                                                :count).by(-1)
      end
    end

    context 'soft' do # rubocop:todo RSpec/ContextWording
      it 'deleted indexed resources' do
        expect do
          envelope.mark_as_deleted!
        end.to change { envelope.reload.deleted_at }.from(nil)
                                                    .and not_change { envelope.reload.purged_at }
          .and change(IndexedEnvelopeResource, :count).by(-1)
      end
    end
  end
end
