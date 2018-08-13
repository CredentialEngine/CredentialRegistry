require 'services/extract_envelope_resources'

describe ExtractEnvelopeResources, type: :service do
  let(:envelope) do
    create(
      :envelope,
      :from_cer,
      resource: jwt_encode(attributes_for(:cer_graph_competency_framework)),
      skip_validation: true
    )
  end

  let(:bnode) do
    envelope.processed_resource_graph.select { |obj| obj['@id'].start_with?('_:') }.first
  end

  let(:graph_objects_except_bnodes) do
    envelope.processed_resource_graph.select { |obj| !(obj['@id'].start_with?('_:')) }
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

  it 'deletes previous envelope objects' do
    create(:envelope_resource, envelope: envelope, processed_resource: attributes_for(:cer_competency))
    expect(envelope.envelope_resources.count).to eq(6)

    ExtractEnvelopeResources.call(envelope: envelope)
    expect(envelope.envelope_resources.count).to eq(5)
  end

  it 'extracts inner objects out of a graph envelope' do
    ExtractEnvelopeResources.call(envelope: envelope)
    expect(envelope.processed_resource_graph.count).to eq(6) # with the bnode
    expect(envelope.envelope_resources.count).to eq(5) # without the bnode
    expect(envelope.envelope_resources.map(&:resource_id)).to(
      match_array(graph_objects_except_bnodes.map { |obj| obj[envelope.id_field].downcase })
    )
  end

  it 'it sets up the attributes properly' do
    expect(uqbar).to_not be_nil
    expect(uqbar_from_graph).to_not be_nil
    expect(uqbar.resource_id).to eq(uqbar_from_graph['@id'])
    expect(uqbar.envelope_id).to eq(envelope.id)
    expect(uqbar.envelope_type).to eq(envelope.envelope_type)
    expect(uqbar.updated_at).to eq(envelope.updated_at)
    expect(uqbar.processed_resource).to eq(uqbar_from_graph)
  end
end
