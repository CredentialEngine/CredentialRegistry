require 'index_envelope_resource'

RSpec.describe IndexEnvelopeResource do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:context_url1) { Faker::Internet.url } # rubocop:todo RSpec/IndexedLet
  let(:context_url2) { Faker::Internet.url } # rubocop:todo RSpec/IndexedLet
  let(:context_url3) { Faker::Internet.url } # rubocop:todo RSpec/IndexedLet
  let(:ctid) { Envelope.generate_ctid }
  let(:envelope_community) { create(:envelope_community, secured: secured) }
  let(:id) { Faker::Internet.url }
  let(:index_resource) { described_class.call(envelope_resource) }
  let(:owner) { nil }
  let(:provisional) { false }
  let(:publisher) { nil }
  let(:secured) { false }
  let(:type) { Faker::Lorem.word }

  let(:envelope) do
    create(
      :envelope,
      envelope_community: envelope_community,
      organization: owner,
      provisional:,
      publishing_organization: publisher,
      resource_publish_type: 'primary'
    )
  end

  let!(:envelope_resource) do
    create(
      :envelope_resource,
      envelope: envelope,
      processed_resource: payload.merge(
        '@id' => id,
        '@type' => type,
        'ceterms:ctid' => ctid
      )
    )
  end

  def find_index(name)
    ActiveRecord::Base
      .connection
      .indexes('indexed_envelope_resources')
      .find { |i| i.name == name }
  end

  before do
    ActiveRecord::Migration.verbose = false

    IndexedEnvelopeResource.reset_column_information

    envelope.update_column(:processed_resource, { '@context' => context_url1 })

    stub_request(:get, context_url1)
      .to_return(body: {
        '@context' => {
          'ceterms:globalJurisdiction' => { '@type' => 'xsd:boolean' },
          'ceterms:temporalCoverage' => { '@type' => 'xsd:date' },
          'ceterms:startTime' => { '@type' => 'xsd:dateTime' },
          'ceterms:weight' => { '@type' => 'xsd:float' },
          'ceterms:medianEarnings' => { '@type' => 'xsd:integer' },
          'ceterms:inLanguage' => { '@type' => 'xsd:language' },
          'ceterms:email' => { '@type' => 'xsd:string' }
        }
      }.to_json)

    stub_request(:get, context_url2)
      .to_return(body: {
        '@context' => {
          'ceterms:name' => { '@container' => '@language' },
          'rdfs:label' => { '@container' => '@language' },
          'skos:note' => { '@container' => '@language' }
        }
      }.to_json)

    stub_request(:get, context_url3)
      .to_return(body: {
        '@context' => {
          'ceterms:contactType' => { '@container' => '@language' },
          'ceterms:offers' => { '@type' => '@id' },
          'ceterms:owns' => { '@type' => '@id' },
          'ceterms:targetContactPoint' => { '@type' => '@id' },
          'ceterms:telephone' => { '@type' => 'xsd:string' }
        }
      }.to_json)
  end

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'CTID uniqueness' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:payload) { {} }

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'duplicate CTID within same community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        create(
          :indexed_envelope_resource,
          envelope_community: envelope_community,
          'ceterms:ctid' => ctid
        )
      end

      it 'raises error' do
        expect { index_resource }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'duplicate CTID within another community' do # rubocop:todo RSpec/ContextWording
      before do
        create(
          :indexed_envelope_resource,
          envelope_community: create(:envelope_community, name: 'ce_registry'),
          'ceterms:ctid' => ctid
        )
      end

      it "doesn't raise error" do
        expect { index_resource }.not_to raise_error
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'missing context entry' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:payload) { { 'foo:bar' => 'wtf' } }

    # rubocop:todo RSpec/MultipleExpectations
    it "doesn't create a column" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      # rubocop:enable RSpec/MultipleExpectations
      expect do
        index_resource
      end.to change(IndexedEnvelopeResource, :count).by(1)

      indexed_resource = IndexedEnvelopeResource.last
      expect(indexed_resource.envelope_community).to eq(envelope_community)
      expect(indexed_resource.public_record?).to be(true)
      expect(indexed_resource.publication_status).to eq('full')
      expect(indexed_resource['@id']).to eq(id)
      expect(indexed_resource['@type']).to eq(type)
      expect(indexed_resource['ceterms:ctid']).to eq(ctid)
      expect(indexed_resource['foo:bar']).to be_nil
      expect(indexed_resource['payload']).to eq(
        envelope_resource.processed_resource
      )

      expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
        envelope.created_at
      )
      expect(indexed_resource['search:recordOwnedBy']).to be_nil
      expect(indexed_resource['search:recordPublishedBy']).to be_nil
      expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
      expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
        envelope.updated_at
      )
      expect(find_index('i_ctdl_foo_bar')).to be_nil
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'language map' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:owner) { create(:organization) }

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'no locales' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { '@context' => context_url2, 'ceterms:name' => value } }
      let(:provisional) { true }
      let(:secured) { true }
      let(:value) { Faker::Lorem.sentence }

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates a single column with a FTS index' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(false)
        expect(indexed_resource.publication_status).to eq('provisional')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:name']).to eq(value)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to be_nil
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_name_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'english\'::regconfig, translate(("ceterms:name")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_ceterms_name_trgm')
        expect(index.columns).to eq(['ceterms:name'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'short locale' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:en_value) { Faker::Lorem.sentence }
      let(:es_value) { Faker::Lorem.sentence }

      let(:payload) do
        {
          '@context' => context_url2,
          'rdfs:label' => { 'en' => en_value, 'es' => es_value }
        }
      end

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates columns for each language with FTS indices' do # rubocop:todo RSpec/ExampleLength
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(true)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['rdfs:label']).to eq(
          "#{en_value} #{es_value}"
        )
        expect(indexed_resource['rdfs:label_en']).to eq(en_value)
        expect(indexed_resource['rdfs:label_es']).to eq(es_value)
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to be_nil
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_rdfs_label_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'english\'::regconfig, translate(("rdfs:label")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_trgm')
        expect(index.columns).to eq(['rdfs:label'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_en_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'english\'::regconfig, translate(("rdfs:label_en")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_en_trgm')
        expect(index.columns).to eq(['rdfs:label_en'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_es_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'spanish\'::regconfig, translate(("rdfs:label_es")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_es_trgm')
        expect(index.columns).to eq(['rdfs:label_es'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'full locale' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:fr_value) { Faker::Lorem.sentence }
      let(:nl_value) { Faker::Lorem.sentence }
      let(:secured) { true }

      let(:payload) do
        {
          '@context' => context_url2,
          'skos:note' => { 'fr_US' => fr_value, 'nl-NL' => nl_value }
        }
      end

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates columns for each language with FTS indices' do # rubocop:todo RSpec/ExampleLength
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(false)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to be_nil
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )
        expect(indexed_resource['skos:note']).to eq("#{fr_value} #{nl_value}")
        expect(indexed_resource['skos:note_fr_us']).to eq(fr_value)
        expect(indexed_resource['skos:note_nl_nl']).to eq(nl_value)

        index = find_index('i_ctdl_skos_note_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'english\'::regconfig, translate(("skos:note")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_trgm')
        expect(index.columns).to eq(['skos:note'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_fr_us_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'french\'::regconfig, translate(("skos:note_fr_us")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_fr_us_trgm')
        expect(index.columns).to eq(['skos:note_fr_us'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_nl_nl_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'dutch\'::regconfig, translate(("skos:note_nl_nl")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_nl_nl_trgm')
        expect(index.columns).to eq(['skos:note_nl_nl'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'plain value' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:publisher) { create(:organization) }

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'xsd:boolean' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { 'ceterms:globalJurisdiction' => value } }
      let(:value) { [false, true].sample }

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates a boolean array column with a GIN index' do # rubocop:todo RSpec/ExampleLength
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(true)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:globalJurisdiction']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to be_nil
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_globalJurisdiction')
        expect(index.columns).to eq(['ceterms:globalJurisdiction'])
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'xsd:date' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { 'ceterms:temporalCoverage' => value } }
      let(:secured) { true }
      let(:value) { Date.current }

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates a date array column with a GIN index' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(false)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:temporalCoverage']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to be_nil
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_temporalCoverage')
        expect(index.columns).to eq(['ceterms:temporalCoverage'])
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'xsd:dateTime' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { 'ceterms:startTime' => value } }
      let(:value) { Time.current.change(usec: 0) }

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates a datetime array column with a GIN index' do # rubocop:todo RSpec/ExampleLength
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(true)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:startTime']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to be_nil
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_startTime')
        expect(index.columns).to eq(['ceterms:startTime'])
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'xsd:float' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { 'ceterms:weight' => value } }
      let(:secured) { true }
      let(:value) { Faker::Number.decimal }

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates a float array column with a GIN index' do # rubocop:todo RSpec/ExampleLength
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(false)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:weight']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to be_nil
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_weight')
        expect(index.columns).to eq(['ceterms:weight'])
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'xsd:integer' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { 'ceterms:medianEarnings' => value } }
      let(:value) { Faker::Number.number(digits: 6) }

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates an integer array column with a GIN index' do # rubocop:todo RSpec/ExampleLength
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(true)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:medianEarnings']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to be_nil
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_medianEarnings')
        expect(index.columns).to eq(['ceterms:medianEarnings'])
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'xsd:language' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { 'ceterms:inLanguage' => value } }
      let(:secured) { true }
      let(:value) { %w[en es ja ru].sample }

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates a string array column with a GIN index' do # rubocop:todo RSpec/ExampleLength
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(false)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:inLanguage']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to be_nil
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_inLanguage')
        expect(index.columns).to eq(['ceterms:inLanguage'])
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'xsd:string' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:payload) { { 'ceterms:email' => [value1, value2] } }
      let(:value1) { Faker::Internet.email } # rubocop:todo RSpec/IndexedLet
      let(:value2) { Faker::Internet.email } # rubocop:todo RSpec/IndexedLet

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates a string column with GIN indices' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          index_resource
        end.to change(IndexedEnvelopeResource, :count).by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to be(true)
        expect(indexed_resource.publication_status).to eq('full')
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:email']).to eq("#{value1} #{value2}")
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to be_nil
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
        expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_email_fts')
        expect(index.columns).to eq(
          # rubocop:todo Layout/LineLength
          'to_tsvector(\'english\'::regconfig, translate(("ceterms:email")::text, \'/.\'::text, \' \'::text))'
          # rubocop:enable Layout/LineLength
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_ceterms_email_trgm')
        expect(index.columns).to eq(['ceterms:email'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'reference' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:owner) { create(:organization) }
    let(:publisher) { create(:organization) }

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'array' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'URIs' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:payload) { { '@context' => context_url3, 'ceterms:owns' => value } }
        let(:provisional) { true }
        let(:secured) { true }
        let(:value) { Array.new(3) { Faker::Internet.url } }

        # rubocop:todo RSpec/MultipleExpectations
        it 'creates references' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            index_resource
          end.to change(IndexedEnvelopeResource, :count).by(1)

          indexed_resource = IndexedEnvelopeResource.last
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource.public_record?).to be(false)
          expect(indexed_resource.publication_status).to eq('provisional')
          expect(indexed_resource['@id']).to eq(id)
          expect(indexed_resource['@type']).to eq(type)
          expect(indexed_resource['ceterms:ctid']).to eq(ctid)
          expect(indexed_resource['payload']).to eq(
            envelope_resource.processed_resource
          )
          expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
            envelope.created_at
          )
          expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
          expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
          # rubocop:todo Layout/LineLength
          expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
          # rubocop:enable Layout/LineLength
          expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
            envelope.updated_at
          )
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:owns')
              .pluck(:resource_uri)
          ).to eq([id, id, id])
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:owns')
              .pluck(:subresource_uri)
          ).to match_array(value)

          expect(find_index('i_ctdl_ceterms_owns')).to be_nil
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'objects with an ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id1) { Faker::Internet.url } # rubocop:todo RSpec/IndexedLet
        let(:id2) { Faker::Internet.url } # rubocop:todo RSpec/IndexedLet

        let(:payload) do
          {
            '@context' => context_url3,
            'ceterms:offers' => [{ '@id' => id1 }, { '@id' => id2 }]
          }
        end

        # rubocop:todo RSpec/MultipleExpectations
        it 'creates references' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            index_resource
          end.to change(IndexedEnvelopeResource, :count).by(1)

          indexed_resource = IndexedEnvelopeResource.last
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource.public_record?).to be(true)
          expect(indexed_resource.publication_status).to eq('full')
          expect(indexed_resource['@id']).to eq(id)
          expect(indexed_resource['@type']).to eq(type)
          expect(indexed_resource['ceterms:ctid']).to eq(ctid)
          expect(indexed_resource['payload']).to eq(
            envelope_resource.processed_resource
          )
          expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
            envelope.created_at
          )
          expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
          expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
          # rubocop:todo Layout/LineLength
          expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
          # rubocop:enable Layout/LineLength
          expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
            envelope.updated_at
          )
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:offers')
              .pluck(:resource_uri)
          ).to eq([id, id])
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:offers')
              .pluck(:subresource_uri)
          ).to contain_exactly(id1, id2)

          expect(find_index('i_ctdl_ceterms_offers')).to be_nil
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'bnodes' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:provisional) { true }
        let(:secured) { true }

        let!(:uuid1) { Faker::Internet.uuid } # rubocop:todo RSpec/IndexedLet
        let!(:uuid2) { Faker::Internet.uuid } # rubocop:todo RSpec/IndexedLet
        let!(:uuid3) { Faker::Internet.uuid } # rubocop:todo RSpec/IndexedLet

        let(:payload) do
          {
            '@context' => context_url3,
            'ceterms:targetContactPoint' => [
              {
                '@type' => 'ceterms:ContactPoint',
                'ceterms:telephone' => ['734-769-8010'],
                'ceterms:contactType' => { 'en' => 'Main Phone Number' }
              },
              {
                '@type' => 'ceterms:ContactPoint',
                'ceterms:telephone' => ['800-673-6275'],
                'ceterms:contactType' => { 'en' => 'Toll Free' }
              },
              {
                '@type' => 'ceterms:ContactPoint',
                'ceterms:telephone' => ['734-769-0109'],
                'ceterms:contactType' => { 'en' => 'Fax' }
              }
            ]
          }
        end

        before do
          # rubocop:todo RSpec/MessageSpies
          # rubocop:todo RSpec/ExpectInHook
          expect(SecureRandom).to receive(:uuid).and_return(uuid1, uuid2, uuid3)
          # rubocop:enable RSpec/ExpectInHook
          # rubocop:enable RSpec/MessageSpies
        end

        # rubocop:todo RSpec/MultipleExpectations
        it 'creates references' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            index_resource
          end.to change(IndexedEnvelopeResource, :count).by(4)

          indexed_resource = IndexedEnvelopeResource.all[0]
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource.public_record?).to be(false)
          expect(indexed_resource.publication_status).to eq('provisional')
          expect(indexed_resource['@id']).to eq(id)
          expect(indexed_resource['@type']).to eq(type)
          expect(indexed_resource['ceterms:ctid']).to eq(ctid)
          expect(indexed_resource['ceterms:targetContactPoint']).to be_nil
          expect(indexed_resource['payload']).to eq(
            envelope_resource.processed_resource
          )
          expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
            envelope.created_at
          )
          expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
          expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
          # rubocop:todo Layout/LineLength
          expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
          # rubocop:enable Layout/LineLength
          expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
            envelope.updated_at
          )
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:targetContactPoint')
              .pluck(:resource_uri)
          ).to eq([id, id, id])
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:targetContactPoint')
              .pluck(:subresource_uri)
          ).to contain_exactly("_:#{uuid1}", "_:#{uuid2}", "_:#{uuid3}")

          expect(find_index('i_ctdl_ceterms_targetContactPoint')).to be_nil

          indexed_resource = IndexedEnvelopeResource.all[1]
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource['@type']).to eq('ceterms:ContactPoint')
          expect(indexed_resource['ceterms:telephone']).to eq('734-769-8010')
          expect(indexed_resource['ceterms:contactType_en']).to eq('Main Phone Number')

          indexed_resource = IndexedEnvelopeResource.all[2]
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource['@type']).to eq('ceterms:ContactPoint')
          expect(indexed_resource['ceterms:telephone']).to eq('800-673-6275')
          expect(indexed_resource['ceterms:contactType_en']).to eq('Toll Free')

          indexed_resource = IndexedEnvelopeResource.all[3]
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource['@type']).to eq('ceterms:ContactPoint')
          expect(indexed_resource['ceterms:telephone']).to eq('734-769-0109')
          expect(indexed_resource['ceterms:contactType_en']).to eq('Fax')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'single object' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'URI' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:payload) { { '@context' => context_url3, 'ceterms:owns' => value } }
        let(:secured) { true }
        let(:value) { Faker::Internet.url }

        # rubocop:todo RSpec/MultipleExpectations
        it 'creates reference' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            index_resource
          end.to change(IndexedEnvelopeResource, :count).by(1)

          indexed_resource = IndexedEnvelopeResource.last
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource.public_record?).to be(false)
          expect(indexed_resource.publication_status).to eq('full')
          expect(indexed_resource['@id']).to eq(id)
          expect(indexed_resource['@type']).to eq(type)
          expect(indexed_resource['ceterms:ctid']).to eq(ctid)
          expect(indexed_resource['payload']).to eq(
            envelope_resource.processed_resource
          )
          expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
            envelope.created_at
          )
          expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
          expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
          # rubocop:todo Layout/LineLength
          expect(indexed_resource['search:resourcePublishType']).to eq(envelope.resource_publish_type)
          # rubocop:enable Layout/LineLength
          expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
            envelope.updated_at
          )
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:owns')
              .pluck(:resource_uri)
          ).to eq([id])
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:owns')
              .pluck(:subresource_uri)
          ).to eq([value])

          expect(find_index('i_ctdl_ceterms_owns')).to be_nil
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'object with an ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id) { Faker::Internet.url }
        let(:payload) { { '@context' => context_url3, 'ceterms:offers' => { '@id' => id } } }
        let(:provisional) { true }

        # rubocop:todo RSpec/MultipleExpectations
        it 'creates reference' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            index_resource
          end.to change(IndexedEnvelopeResource, :count).by(1)

          indexed_resource = IndexedEnvelopeResource.last
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource.public_record?).to be(true)
          expect(indexed_resource.publication_status).to eq('provisional')
          expect(indexed_resource['@id']).to eq(id)
          expect(indexed_resource['@type']).to eq(type)
          expect(indexed_resource['ceterms:ctid']).to eq(ctid)
          expect(indexed_resource['payload']).to eq(
            envelope_resource.processed_resource
          )
          expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
            envelope.created_at
          )
          expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
          expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
          expect(indexed_resource['search:resourcePublishType']).to eq(
            envelope.resource_publish_type
          )
          expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
            envelope.updated_at
          )
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:offers')
              .pluck(:resource_uri)
          ).to eq([id])
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:offers')
              .pluck(:subresource_uri)
          ).to eq([id])

          expect(find_index('i_ctdl_ceterms_offers')).to be_nil
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'bnodes' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:secured) { true }

        let!(:uuid) { Faker::Internet.uuid }

        let(:payload) do
          {
            '@context' => context_url3,
            'ceterms:targetContactPoint' => {
              '@type' => 'ceterms:ContactPoint',
              'ceterms:telephone' => ['734-769-8010'],
              'ceterms:contactType' => { 'en' => 'Main Phone Number' }
            }
          }
        end

        before do
          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          expect(SecureRandom).to receive(:uuid).and_return(uuid) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
          # rubocop:enable RSpec/MessageSpies
          # rubocop:enable RSpec/StubbedMock
        end

        # rubocop:todo RSpec/MultipleExpectations
        it 'creates references' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            index_resource
          end.to change(IndexedEnvelopeResource, :count).by(2)

          indexed_resource = IndexedEnvelopeResource.all[0]
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource.public_record?).to be(false)
          expect(indexed_resource.publication_status).to eq('full')
          expect(indexed_resource['@id']).to eq(id)
          expect(indexed_resource['@type']).to eq(type)
          expect(indexed_resource['ceterms:ctid']).to eq(ctid)
          expect(indexed_resource['ceterms:targetContactPoint']).to be_nil
          expect(indexed_resource['payload']).to eq(
            envelope_resource.processed_resource
          )
          expect(indexed_resource['search:recordCreated']).to be_within(1.second).of(
            envelope.created_at
          )
          expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
          expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
          expect(indexed_resource['search:resourcePublishType']).to eq(
            envelope.resource_publish_type
          )
          expect(indexed_resource['search:recordUpdated']).to be_within(1.second).of(
            envelope.updated_at
          )
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:targetContactPoint')
              .pluck(:resource_uri)
          ).to eq([id])
          expect(
            indexed_resource
              .references
              .where(path: 'ceterms:targetContactPoint')
              .pluck(:subresource_uri)
          ).to eq(["_:#{uuid}"])

          expect(find_index('i_ctdl_ceterms_targetContactPoint')).to be_nil

          indexed_resource = IndexedEnvelopeResource.last
          expect(indexed_resource.envelope_community).to eq(envelope_community)
          expect(indexed_resource['@type']).to eq('ceterms:ContactPoint')
          expect(indexed_resource['ceterms:telephone']).to eq('734-769-8010')
          expect(indexed_resource['ceterms:contactType_en']).to eq('Main Phone Number')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
