require 'services/extract_envelope_resources'

RSpec.describe ExtractEnvelopeResources, type: :service do
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

  it 'deletes previous envelope objects' do
    resource_ids = []

    expect(IndexEnvelopeResourceJob).to receive(:perform_later).exactly(6).times do |resource_id|
      resource_ids << resource_id
    end

    create(:envelope_resource, envelope: envelope, processed_resource: attributes_for(:cer_competency))
    previous_resources = envelope.envelope_resources.to_a
    ExtractEnvelopeResources.call(envelope: envelope)
    current_resources = envelope.reload.envelope_resources.to_a
    expect(previous_resources & current_resources).to eq([])
    expect(envelope.envelope_resource_ids).to match_array(resource_ids)
  end

  it 'extracts inner objects out of a graph envelope' do
    resource_ids = []

    expect(IndexEnvelopeResourceJob).to receive(:perform_later).exactly(6).times do |resource_id|
      resource_ids << resource_id
    end

    ExtractEnvelopeResources.call(envelope: envelope)
    expect(envelope.processed_resource_graph.count).to eq(6)
    expect(envelope.envelope_resources.count).to eq(6)
    expect(envelope.envelope_resources.map(&:resource_id)).to(
      match_array(
        envelope.processed_resource_graph.map do |obj|
          obj[envelope.id_field]&.downcase || obj.fetch('@id')
        end
      )
    )
    expect(envelope.envelope_resource_ids).to match_array(resource_ids)
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
