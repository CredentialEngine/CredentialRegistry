require 'envelope'

default_props = {
  'ceterms:description' => 'Description',
  'ceterms:name' => 'Name'
}

RSpec.describe Envelope, type: :model do # rubocop:todo RSpec/SpecFilePathFormat
  context 'CE registry' do # rubocop:todo RSpec/ContextWording
    # rubocop:disable Layout/LineLength
    shared_examples 'ce registry searchable' do |resource_type, resource_factory, with_webpage = true, props = default_props|
      # rubocop:enable Layout/LineLength
      let(:envelope) do
        create(:envelope,
               :from_cer,
               resource: jwt_encode(resource),
               resource_type: resource_type,
               skip_validation: true)
      end

      let(:resource) do
        props['ceterms:subjectWebpage'] = 'https://example.com/path?query' if with_webpage

        res = build(resource_factory)
        if res[:@graph].present?
          res[:@graph].find { |obj| obj[:'ceterms:ctid'] == res[:'ceterms:ctid'] }.merge!(props)
        else
          res.merge!(props)
        end
        res
      end

      let(:envelope_resources) { envelope.envelope_resources }

      it 'sets FTS attributes' do
        found = envelope_resources.select do |obj|
          trigram = obj.fts_trigram == 'Name'
          tsearch = obj.fts_tsearch == if with_webpage
                                         "Name\nDescription\nhttps //example.com/path query"
                                       else
                                         "Name\nDescription"
                                       end
          trigram && tsearch
        end
        expect(found.count).to eq(1)
      end
    end

    context 'assessment profile' do # rubocop:todo RSpec/ContextWording
      it_behaves_like 'ce registry searchable',
                      'assessment_profile',
                      :cer_ass_prof
    end

    context 'condition manifest schema' do # rubocop:todo RSpec/ContextWording
      it_behaves_like 'ce registry searchable',
                      'condition_manifest_schema',
                      :cer_cond_man
    end

    context 'cost manifest schema' do # rubocop:todo RSpec/ContextWording
      it_behaves_like 'ce registry searchable',
                      'cost_manifest_schema',
                      :cer_cost_man, true
    end

    context 'graph - competency framework' do # rubocop:todo RSpec/ContextWording
      it_behaves_like 'ce registry searchable',
                      'competency_framework_schema',
                      :cer_graph_competency_framework,
                      false,
                      'ceasn:description' => {
                        'en-us' => 'Description'
                      },
                      'ceasn:name' => {
                        'en-us' => 'Name'
                      }
    end

    context 'credential' do # rubocop:todo RSpec/ContextWording
      it_behaves_like 'ce registry searchable', 'credential', :cer_cred
    end

    context 'learning opportunity profile' do # rubocop:todo RSpec/ContextWording
      it_behaves_like 'ce registry searchable',
                      'learning_opportunity_profile',
                      :cer_lrn_opp_prof, true
    end

    context 'organization' do # rubocop:todo RSpec/ContextWording
      let(:envelope) do
        create(:envelope,
               :from_cer,
               resource: jwt_encode(resource),
               resource_type: 'organization')
      end

      let(:envelope_resource) { envelope.envelope_resources.first }

      let(:resource) do
        build(:cer_org).merge(
          'ceterms:agentPurpose' => 'AgentPurpose',
          'ceterms:agentPurposeDescription' => 'AgentPurposeDescription',
          'ceterms:description' => 'Description',
          'ceterms:name' => 'Name',
          'ceterms:subjectWebpage' => 'https://example.com/path?query'
        )
      end

      it 'sets FTS attributes' do
        expect(envelope_resource.fts_trigram).to eq('Name')
        expect(envelope_resource.fts_tsearch).to eq(
          "Name\nDescription\nAgentPurpose\nAgentPurposeDescription\n" \
          'https //example.com/path query'
        )
      end
    end

    context 'language maps' do # rubocop:todo RSpec/ContextWording
      let(:envelope) do
        create(:envelope,
               :from_cer,
               resource: jwt_encode(resource),
               resource_type: 'organization',
               skip_validation: true)
      end

      let(:envelope_resource) { envelope.envelope_resources.first }

      let(:resource) do
        build(:cer_org).merge(
          'ceterms:agentPurpose' => 'AgentPurpose',
          'ceterms:agentPurposeDescription' => 'AgentPurposeDescription',
          'ceterms:description' => { 'en' => ['Description 1', 'Description 2'] },
          'ceterms:name' => { 'en' => 'Name', 'es' => 'Nombre' },
          'ceterms:subjectWebpage' => 'https://example.com/path?query'
        )
      end

      it 'sets FTS attributes' do
        expect(envelope_resource.fts_trigram).to eq("Name\nNombre")
        expect(envelope_resource.fts_tsearch).to eq(
          "Name\nNombre\nDescription 1\nDescription 2\nAgentPurpose\nAgentPurposeDescription\n" \
          'https //example.com/path query'
        )
      end
    end
  end

  context 'learning registry' do # rubocop:todo RSpec/ContextWording
    let(:envelope) { create(:envelope, resource: jwt_encode(resource)) }
    let(:envelope_resource) { envelope.envelope_resources.first }
    let(:resource) do
      {
        description: 'Description',
        keywords: 'Keywords',
        name: 'Name',
        url: 'https://example.com'
      }
    end

    it 'sets FTS attributes' do
      expect(envelope_resource.fts_trigram).to eq("Name\nKeywords")
      expect(envelope_resource.fts_tsearch).to eq("Name\nKeywords\nDescription")
    end
  end
end
