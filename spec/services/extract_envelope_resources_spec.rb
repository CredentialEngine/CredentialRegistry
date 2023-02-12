require 'services/extract_envelope_resources'

RSpec.describe ExtractEnvelopeResources, type: :service do
  context 'extraction' do
    let(:envelope) do
      create(
        :envelope,
        :from_cer,
        resource: jwt_encode(
          attributes_for(
            :cer_graph_competency_framework,
            '@graph': [resource1, resource2, resource3]
          )
        ),
        skip_validation: true
      )
    end

    let(:resource1) { attributes_for(:cer_competency) }
    let(:resource2) { attributes_for(:cer_competency) }
    let(:resource3) { attributes_for(:cer_competency) }
    let(:new_resource) { attributes_for(:cer_competency) }
    let(:unchanged_resource) { resource1 }
    let(:updated_resource) do
      attributes_for(:cer_competency, ctid: resource2.fetch(:'ceterms:ctid'))
    end

    before do
      EnvelopeResource.delete_all
      ExtractEnvelopeResources.call(envelope: envelope)
    end

    it 'extracts graph objects' do
      envelope.update!(
        resource: jwt_encode(
          attributes_for(
            :cer_graph_competency_framework,
            '@graph': [new_resource, unchanged_resource, updated_resource]
          )
        ),
        skip_validation: true
      )

      expect(envelope.envelope_resources.pluck(:resource_id)).to match_array(
        [resource1, resource2, resource3].map { |r| r[:'ceterms:ctid'] }
      )

      ExtractEnvelopeResources.call(envelope:)

      expect(envelope.envelope_resources.pluck(:resource_id)).to match_array(
        [new_resource, unchanged_resource, updated_resource].map { |r| r[:'ceterms:ctid'] }
      )
    end
  end

  context 'FTS attrs' do
    let(:envelope) do
      create(
        :envelope,
        :from_cer,
        resource: jwt_encode(attributes_for(:cer_graph_competency_framework)),
        skip_validation: true
      )
    end

    let(:uqbar) do
      envelope.envelope_resources.select do |obj|
        obj.processed_resource['ceasn:competencyText'].try(:[], 'en-us') == 'Uqbar'
      end.first
    end

    let(:uqbar_from_graph) do
      envelope.envelope_resources.map(&:processed_resource).select do |res|
        res['ceasn:competencyText'].try(:[], 'en-us') == 'Uqbar'
      end.first
    end

    it 'it sets up the attributes properly' do
      expect(uqbar).to_not be_nil
      expect(uqbar_from_graph).to_not be_nil
      expect(uqbar.resource_id).to eq(uqbar_from_graph['@id'])
      expect(uqbar.envelope_id).to eq(envelope.id)
      expect(uqbar.envelope_type).to eq(envelope.envelope_type)
      expect(uqbar.processed_resource).to eq(uqbar_from_graph)
    end
  end
end
