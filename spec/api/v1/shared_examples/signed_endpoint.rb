shared_examples 'a signed endpoint' do |verb|
  before do
    @endpoint = '/api/envelopes'
    unless verb == :post
      envelope = create(:envelope, :with_id)
      @endpoint += "/#{envelope.envelope_id}"
    end
  end

  context 'using a malformed or invalid public key' do
    before(:each) do
      send(verb, @endpoint, attributes_for(:envelope, :with_malformed_key))
    end

    it { expect_status(:bad_request) }

    it 'raises a key decoding error' do
      expect_json('errors.0', 'Neither PUB key nor PRIV key')
    end
  end

  context 'using a public key that does not match the token' do
    before(:each) do
      send(verb, @endpoint, attributes_for(:envelope, :with_different_key))
    end

    it { expect_status(:bad_request) }

    it 'raises a key decoding error' do
      expect_json('errors.0', 'Signature verification raised')
    end
  end
end
