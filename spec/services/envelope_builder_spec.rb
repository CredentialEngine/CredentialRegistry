require 'envelope_builder'

RSpec.describe EnvelopeBuilder, type: :service do
  let(:envelope_community) do
    EnvelopeCommunity.create_with(
      backup_item: 'ce-registry-test'
    ).find_or_create_by!(name: 'ce_registry')
  end

  let(:envelope) do
    attributes_for(:envelope, :with_graph_competency_framework).merge(
      'envelope_community' => envelope_community.name
    )
  end

  it 'builds a new envelope and indexes its resources' do
    created, = EnvelopeBuilder.new(
      envelope,
      update_if_exists: true,
      skip_validation: true
    ).build
    expect(created.persisted?).to be true
    expect(created.envelope_resources.count).to eq(5)
  end
end
