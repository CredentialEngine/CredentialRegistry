shared_examples 'a signed endpoint' do |verb, uses_id: false, params: {}|
  before do
    @endpoint = '/api/envelopes'
    if uses_id
      envelope = create(:envelope, :with_id)
      @endpoint += "/#{envelope.envelope_id}"
    end
    @entity = verb == :delete ? :delete_token : :envelope
  end

  context 'using a malformed or invalid public key' do
    before(:each) do
      send(verb, @endpoint, attributes_for(@entity, :with_malformed_key)
                              .merge(params))
    end

    it { expect_status(:bad_request) }

    it 'raises a key decoding error' do
      expect_json('errors.0', 'Neither PUB key nor PRIV key')
    end
  end

  context 'using a public key that does not match the token' do
    before(:each) do
      send(verb, @endpoint, attributes_for(@entity, :with_different_key)
                              .merge(params))
    end

    it { expect_status(:bad_request) }

    it 'raises a key decoding error' do
      expect_json('errors.0', 'Signature verification raised')
    end
  end
end
