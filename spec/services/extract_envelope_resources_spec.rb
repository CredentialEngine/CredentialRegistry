require 'services/extract_envelope_resources'

RSpec.describe ExtractEnvelopeResources, type: :service do
  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'extraction' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:envelope) do
      create(
        :envelope,
        :from_cer,
        resource: jwt_encode(
          attributes_for(
            :cer_graph_competency_framework,
            '@graph': [resource1, resource2, resource3]
          )
        )
      )
    end

    let(:resource1) { attributes_for(:cer_competency) } # rubocop:todo RSpec/IndexedLet
    let(:resource2) { attributes_for(:cer_competency) } # rubocop:todo RSpec/IndexedLet
    let(:resource3) { attributes_for(:cer_competency) } # rubocop:todo RSpec/IndexedLet
    let(:new_resource) { attributes_for(:cer_competency) }
    let(:unchanged_resource) { resource1 }
    let(:updated_resource) do
      attributes_for(:cer_competency, ctid: resource2.fetch(:'ceterms:ctid'))
    end

    before do
      EnvelopeResource.delete_all
      described_class.call(envelope: envelope)
    end

    it 'extracts graph objects' do # rubocop:todo RSpec/ExampleLength
      envelope.update!(
        resource: jwt_encode(
          attributes_for(
            :cer_graph_competency_framework,
            '@graph': [new_resource, unchanged_resource, updated_resource]
          )
        )
      )

      expect(envelope.envelope_resources.pluck(:resource_id)).to match_array(
        [resource1, resource2, resource3].map { |r| r[:'ceterms:ctid'] }
      )

      described_class.call(envelope:)

      expect(envelope.envelope_resources.pluck(:resource_id)).to match_array(
        [new_resource, unchanged_resource, updated_resource].map { |r| r[:'ceterms:ctid'] }
      )
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'FTS attrs' do # rubocop:todo RSpec/ContextWording
    let(:envelope) do
      create(
        :envelope,
        :from_cer,
        resource: jwt_encode(attributes_for(:cer_graph_competency_framework))
      )
    end

    let(:uqbar) do
      envelope.envelope_resources.find do |obj|
        obj.processed_resource['ceasn:competencyText'].try(:[], 'en-us') == 'Uqbar'
      end
    end

    let(:uqbar_from_graph) do
      envelope.envelope_resources.map(&:processed_resource).find do |res|
        res['ceasn:competencyText'].try(:[], 'en-us') == 'Uqbar'
      end
    end

    it 'sets up the attributes properly' do # rubocop:todo RSpec/MultipleExpectations
      expect(uqbar).not_to be_nil
      expect(uqbar_from_graph).not_to be_nil
      expect(uqbar.resource_id).to eq(uqbar_from_graph['@id'])
      expect(uqbar.envelope_id).to eq(envelope.id)
      expect(uqbar.envelope_type).to eq(envelope.envelope_type)
      expect(uqbar.processed_resource).to eq(uqbar_from_graph)
    end
  end
end
