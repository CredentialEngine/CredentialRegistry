describe OriginalUserValidator do
  subject(:envelope) { create(:envelope) }
  let(:resource) { build(:resource) }

  it 'rejects update when the original key is not present as a location' do
    resource
      .learning_registry_metadata
      .digital_signature
      .key_location = ['http://example.org/otherkey']
    envelope.resource = JWT.encode(resource, nil, 'none')

    envelope.save

    expect(envelope.errors[:resource]).to include('Only the original '\
                                                  'user can update a resource')
  end
end
