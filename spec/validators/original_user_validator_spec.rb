describe OriginalUserValidator do
  subject(:document) { create(:document) }
  let(:resource) { build(:resource) }

  it 'rejects update when the original key is not present as a location' do
    resource
      .learning_registry_metadata
      .digital_signature
      .key_location = ['http://example.org/otherkey']
    document.user_envelope = JWT.encode(resource, nil, 'none')

    document.save

    expect(document.errors[:user_envelope]).to include('Only the original '\
                                               'user can update a resource')
  end
end
