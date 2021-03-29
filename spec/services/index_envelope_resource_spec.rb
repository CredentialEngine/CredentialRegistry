require 'index_envelope_resource'

RSpec.describe IndexEnvelopeResource do
  let(:context) { {} }
  let(:ctid) { Envelope.generate_ctid }
  let(:envelope_community) { create(:envelope_community, secured: secured) }
  let(:id) { Faker::Internet.url }
  let(:index_resource) { IndexEnvelopeResource.call(envelope_resource) }
  let(:owner) { nil }
  let(:publisher) { nil }
  let(:secured) { false }
  let(:type) { Faker::Lorem.word }

  let(:envelope) do
    create(
      :envelope,
      envelope_community: envelope_community,
      organization: owner,
      publishing_organization: publisher
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

    JsonContext.create!(
      context: {
        '@context' => {
          'ceterms:name' => { '@container' => '@language' },
          'rdfs:label' => { '@container' => '@language' },
          'skos:note' => { '@container' => '@language' }
        }
      },
      url: Faker::Internet.url
    )

    JsonContext.create!(
      context: {
        '@context' => {
          'ceterms:globalJurisdiction' => { '@type' => 'xsd:boolean' },
          'ceterms:temporalCoverage' => { '@type' => 'xsd:date' },
          'ceterms:startTime' => { '@type' => 'xsd:dateTime' },
          'ceterms:weight' => { '@type' => 'xsd:float' },
          'ceterms:medianEarnings' => { '@type' => 'xsd:integer' },
          'ceterms:inLanguage' => { '@type' => 'xsd:language' },
          'ceterms:email' => { '@type' => 'xsd:string' }
        }
      },
      url: Faker::Internet.url
    )

    JsonContext.create!(
      context: {
        '@context' => {
          'ceterms:contactType' => { '@container' => '@language' },
          'ceterms:offers' => { '@type' => '@id' },
          'ceterms:owns' => { '@type' => '@id' },
          'ceterms:targetContactPoint' => { '@type' => '@id' },
          'ceterms:telephone' => { '@type' => 'xsd:string' }
        }
      },
      url: Faker::Internet.url
    )

    IndexedEnvelopeResource.reset_column_information
  end

  context 'CTID uniqueness' do
    let(:payload) { {} }

    context 'duplicate CTID within same community' do
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

    context 'duplicate CTID within another community' do
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
  end

  context 'missing context entry' do
    let(:payload) { { 'foo:bar' => 'wtf' } }

    it "doesn't create a column" do
      expect {
        index_resource
      }.to change { IndexedEnvelopeResource.count }.by(1)

      indexed_resource = IndexedEnvelopeResource.last
      expect(indexed_resource.envelope_community).to eq(envelope_community)
      expect(indexed_resource.public_record?).to eq(true)
      expect(indexed_resource['@id']).to eq(id)
      expect(indexed_resource['@type']).to eq(type)
      expect(indexed_resource['ceterms:ctid']).to eq(ctid)
      expect(indexed_resource['foo:bar']).to eq(nil)
      expect(indexed_resource['payload']).to eq(
        envelope_resource.processed_resource
      )
      expect(indexed_resource['search:recordCreated']).to eq(
        envelope.created_at
      )
      expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
      expect(indexed_resource['search:recordPublishedBy']).to eq(nil)
      expect(indexed_resource['search:recordUpdated']).to eq(
        envelope.updated_at
      )
      expect(find_index('i_ctdl_foo_bar')).to eq(nil)
    end
  end

  context 'language map' do
    let(:owner) { create(:organization) }

    context 'no locales' do
      let(:payload) { { 'ceterms:name' => value } }
      let(:secured) { true }
      let(:value) { Faker::Lorem.sentence }

      it 'creates a single column with a FTS index' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(false)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:name']).to eq(value)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to eq(nil)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_name_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'english\'::regconfig, translate(("ceterms:name")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_ceterms_name_trgm')
        expect(index.columns).to eq(['ceterms:name'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end

    context 'short locale' do
      let(:en_value) { Faker::Lorem.sentence }
      let(:es_value) { Faker::Lorem.sentence }

      let(:payload) do
        { 'rdfs:label' => { 'en' => en_value, 'es' => es_value } }
      end

      it 'creates columns for each language with FTS indices' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(true)
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
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to eq(nil)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_rdfs_label_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'english\'::regconfig, translate(("rdfs:label")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_trgm')
        expect(index.columns).to eq(['rdfs:label'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_en_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'english\'::regconfig, translate(("rdfs:label_en")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_en_trgm')
        expect(index.columns).to eq(['rdfs:label_en'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_es_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'spanish\'::regconfig, translate(("rdfs:label_es")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_rdfs_label_es_trgm')
        expect(index.columns).to eq(['rdfs:label_es'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end

    context 'full locale' do
      let(:en_value) { Faker::Lorem.sentence }
      let(:fr_value) { Faker::Lorem.sentence }
      let(:secured) { true }

      let(:payload) do
        { 'skos:note' => { 'en-us' => en_value, 'fr_US' => fr_value } }
      end

      it 'creates columns for each language with FTS indices' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(false)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to eq(nil)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )
        expect(indexed_resource['skos:note']).to eq(
          "#{en_value} #{fr_value}"
        )
        expect(indexed_resource['skos:note_en_us']).to eq(en_value)
        expect(indexed_resource['skos:note_fr_us']).to eq(fr_value)

        index = find_index('i_ctdl_skos_note_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'english\'::regconfig, translate(("skos:note")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_trgm')
        expect(index.columns).to eq(['skos:note'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_en_us_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'english\'::regconfig, translate(("skos:note_en_us")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_en_us_trgm')
        expect(index.columns).to eq(['skos:note_en_us'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_fr_us_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'french\'::regconfig, translate(("skos:note_fr_us")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_skos_note_fr_us_trgm')
        expect(index.columns).to eq(['skos:note_fr_us'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end
  end

  context 'plain value' do
    let(:publisher) { create(:organization) }

    context 'xsd:boolean' do
      let(:payload) { { 'ceterms:globalJurisdiction' => value } }
      let(:value) { [false, true].sample }

      it 'creates a boolean array column with a GIN index' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(true)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:globalJurisdiction']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_globalJurisdiction')
        expect(index.columns).to eq(['ceterms:globalJurisdiction'])
        expect(index.using).to eq(:gin)
      end
    end

    context 'xsd:date' do
      let(:payload) { { 'ceterms:temporalCoverage' => value } }
      let(:secured) { true }
      let(:value) { Date.current }

      it 'creates a date array column with a GIN index' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(false)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:temporalCoverage']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_temporalCoverage')
        expect(index.columns).to eq(['ceterms:temporalCoverage'])
        expect(index.using).to eq(:gin)
      end
    end

    context 'xsd:dateTime' do
      let(:payload) { { 'ceterms:startTime' => value } }
      let(:value) { Time.current.change(usec: 0) }

      it 'creates a datetime array column with a GIN index' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(true)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:startTime']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_startTime')
        expect(index.columns).to eq(['ceterms:startTime'])
        expect(index.using).to eq(:gin)
      end
    end

    context 'xsd:float' do
      let(:payload) { { 'ceterms:weight' => value } }
      let(:secured) { true }
      let(:value) { Faker::Number.decimal }

      it 'creates a float array column with a GIN index' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(false)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:weight']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_weight')
        expect(index.columns).to eq(['ceterms:weight'])
        expect(index.using).to eq(:gin)
      end
    end

    context 'xsd:integer' do
      let(:payload) { { 'ceterms:medianEarnings' => value } }
      let(:value) { Faker::Number.number(digits: 6) }

      it 'creates an integer array column with a GIN index' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(true)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:medianEarnings']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_medianEarnings')
        expect(index.columns).to eq(['ceterms:medianEarnings'])
        expect(index.using).to eq(:gin)
      end
    end

    context 'xsd:language' do
      let(:payload) { { 'ceterms:inLanguage' => value } }
      let(:secured) { true }
      let(:value) { %w[en es ja ru].sample }

      it 'creates a string array column with a GIN index' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(false)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:inLanguage']).to eq([value])
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_inLanguage')
        expect(index.columns).to eq(['ceterms:inLanguage'])
        expect(index.using).to eq(:gin)
      end
    end

    context 'xsd:string' do
      let(:payload) { { 'ceterms:email' => [value1, value2] } }
      let(:value1) { Faker::Internet.email }
      let(:value2) { Faker::Internet.email }

      it 'creates a string column with GIN indices' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(true)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:email']).to eq("#{value1} #{value2}")
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(nil)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
          envelope.updated_at
        )

        index = find_index('i_ctdl_ceterms_email_fts')
        expect(index.columns).to eq(
          'to_tsvector(\'english\'::regconfig, translate(("ceterms:email")::text, \'/.\'::text, \' \'::text))'
        )
        expect(index.using).to eq(:gin)

        index = find_index('i_ctdl_ceterms_email_trgm')
        expect(index.columns).to eq(['ceterms:email'])
        expect(index.opclasses).to eq(:gin_trgm_ops)
        expect(index.using).to eq(:gin)
      end
    end
  end

  context 'reference' do
    let(:owner) { create(:organization) }
    let(:publisher) { create(:organization) }

    context 'array or URIs' do
      let(:payload) { { 'ceterms:owns' => value } }
      let(:secured) { true }
      let(:value) { 3.times.map { Faker::Internet.url } }

      it 'creates references' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(false)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
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

        expect(find_index('i_ctdl_ceterms_owns')).to eq(nil)
      end
    end

    context 'array of objects with an ID' do
      let(:id1) { Faker::Internet.url }
      let(:id2) { Faker::Internet.url }

      let(:payload) do
        { 'ceterms:offers' => [{ '@id' => id1 }, { '@id' => id2 }] }
      end

      it 'creates references' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(1)

        indexed_resource = IndexedEnvelopeResource.last
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(true)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
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
        ).to match_array([id1, id2])

        expect(find_index('i_ctdl_ceterms_offers')).to eq(nil)
      end
    end

    context 'array of bnodes' do
      let(:secured) { true }

      let!(:uuid1) { Faker::Internet.uuid }
      let!(:uuid2) { Faker::Internet.uuid }
      let!(:uuid3) { Faker::Internet.uuid }

      let(:payload) do
        {
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
        expect(SecureRandom).to receive(:uuid).and_return(uuid1, uuid2, uuid3)
      end

      it 'creates references' do
        expect {
          index_resource
        }.to change { IndexedEnvelopeResource.count }.by(4)

        indexed_resource = IndexedEnvelopeResource.all[0]
        expect(indexed_resource.envelope_community).to eq(envelope_community)
        expect(indexed_resource.public_record?).to eq(false)
        expect(indexed_resource['@id']).to eq(id)
        expect(indexed_resource['@type']).to eq(type)
        expect(indexed_resource['ceterms:ctid']).to eq(ctid)
        expect(indexed_resource['ceterms:targetContactPoint']).to eq(nil)
        expect(indexed_resource['payload']).to eq(
          envelope_resource.processed_resource
        )
        expect(indexed_resource['search:recordCreated']).to eq(
          envelope.created_at
        )
        expect(indexed_resource['search:recordOwnedBy']).to eq(owner._ctid)
        expect(indexed_resource['search:recordPublishedBy']).to eq(publisher._ctid)
        expect(indexed_resource['search:recordUpdated']).to eq(
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
        ).to match_array([
          "_:#{uuid1}", "_:#{uuid2}", "_:#{uuid3}"
        ])

        expect(find_index('i_ctdl_ceterms_targetContactPoint')).to eq(nil)

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
  end
end
