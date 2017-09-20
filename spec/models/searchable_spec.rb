require 'envelope'

describe Envelope, type: :model do
  context 'CE registry' do
    # rubocop:disable Metrics/LineLength
    shared_examples 'ce registry searchable' do |resource_type, resource_factory, with_webpage = true|
      # rubocop:enable Metrics/LineLength
      let(:envelope) do
        create(:envelope,
               :from_cer,
               resource: jwt_encode(resource),
               resource_type: resource_type)
      end

      let(:resource) do
        props = {
          'ceterms:description' => 'Description',
          'ceterms:name' => 'Name'
        }

        if with_webpage
          props['ceterms:subjectWebpage'] = [{
            '@id' => 'https://example.com/path?query'
          }]
        end

        build(resource_factory).merge(props)
      end

      it 'sets FTS attributes' do
        expect(envelope.fts_trigram).to eq('Name')
        if with_webpage
          expect(envelope.fts_tsearch).to eq(
            "Name\nDescription\nhttps //example.com/path query"
          )
        else
          expect(envelope.fts_tsearch).to eq("Name\nDescription")
        end
      end
    end

    context 'assessment profile' do
      it_behaves_like 'ce registry searchable',
                      'assessment_profile',
                      :cer_ass_prof
    end

    context 'condition manifest schema' do
      it_behaves_like 'ce registry searchable',
                      'condition_manifest_schema',
                      :cer_cond_man
    end

    context 'cost manifest schema' do
      it_behaves_like 'ce registry searchable',
                      'cost_manifest_schema',
                      :cer_cost_man, false
    end

    context 'credential' do
      it_behaves_like 'ce registry searchable', 'credential', :cer_cred
    end

    context 'learning opportunity profile' do
      it_behaves_like 'ce registry searchable',
                      'learning_opportunity_profile',
                      :cer_lrn_opp_prof, false
    end

    context 'organization' do
      let(:envelope) do
        create(:envelope,
               :from_cer,
               resource: jwt_encode(resource),
               resource_type: 'organization')
      end

      let(:resource) do
        build(:cer_org).merge(
          'ceterms:agentPurpose' => { '@id' => 'AgentPurpose' },
          'ceterms:agentPurposeDescription' => 'AgentPurposeDescription',
          'ceterms:description' => 'Description',
          'ceterms:name' => 'Name',
          'ceterms:subjectWebpage' => [{
            '@id' => 'https://example.com/path?query'
          }]
        )
      end

      it 'sets FTS attributes' do
        expect(envelope.fts_trigram).to eq('Name')
        expect(envelope.fts_tsearch).to eq(
          "Name\nDescription\nAgentPurpose\nAgentPurposeDescription\n" \
          'https //example.com/path query'
        )
      end
    end
  end

  context 'learning registry' do
    let(:envelope) { create(:envelope, resource: jwt_encode(resource)) }
    let(:resource) do
      {
        description: 'Description',
        keywords: 'Keywords',
        name: 'Name',
        url: 'https://example.com'
      }
    end

    it 'sets FTS attributes' do
      expect(envelope.fts_trigram).to eq("Name\nKeywords")
      expect(envelope.fts_tsearch).to eq("Name\nKeywords\nDescription")
    end
  end
end
