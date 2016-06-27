describe ResourceSchemaValidator do
  subject(:envelope) { build(:envelope) }

  it 'validates a Learning Registry community resource using its schema' do
    expect(envelope.valid?).to eq(true)
  end

  it 'raises a validation error when schema does not match' do
    envelope.resource = jwt_encode(attributes_for(:resource, url: 0))

    envelope.validate

    expect(envelope.errors[:resource].first).to(
      include('JSON Schema validation errors')
    )
  end

  it 'picks up the right schema' do
    allow(envelope).to receive(:community_name) { 'credential_registry' }
    envelope.resource = jwt_encode(
      attributes_for(:credential_registry_org, 'schema:description': 0)
    )

    expect(envelope.valid?).to eq(false)
  end
end
