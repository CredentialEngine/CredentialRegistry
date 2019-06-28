RSpec.describe OriginalUserValidator do
  subject(:envelope) { create(:envelope) }
  let(:resource) { build(:resource) }

  it 'rejects update when the original key is not present as a location' do
    resource
      .registry_metadata
      .digital_signature
      .key_location = ['http://example.org/another_key']
    envelope.resource = jwt_encode(resource)

    envelope.validate

    expect(envelope.errors[:resource]).to(
      include('can only be updated by the original user. ' \
              'There is a public key or key locations mismatch.')
    )
  end

  it 'rejects update when the keys differ' do
    envelope.assign_attributes(attributes_for(:envelope,
                                              :from_different_user))

    envelope.validate

    expect(envelope.errors[:resource]).to(
      include('can only be updated by the original user. ' \
              'There is a public key or key locations mismatch.')
    )
  end

  it 'accepts update when the key belongs to an administrative account' do
    create(:administrative_account)
    envelope.assign_attributes(attributes_for(:envelope,
                                              :from_administrative_account))

    expect(envelope.valid?).to eq(true)
  end
end
