RSpec.shared_examples 'a signed endpoint' do |verb, uses_id: false, params: {}|
  before do
    @endpoint = '/learning-registry/envelopes'
    if uses_id
      envelope = create(:envelope)
      @endpoint += "/#{envelope.envelope_id}"
    end
    @entity = %i[delete put].include?(verb) ? :delete_envelope : :envelope
  end

  context 'using a malformed or invalid public key' do # rubocop:todo RSpec/ContextWording
    before do
      # rubocop:todo RSpec/InstanceVariable
      send(verb, @endpoint, attributes_for(@entity, :with_malformed_key)
                              # rubocop:enable RSpec/InstanceVariable
                              .merge(params))
    end

    it { expect_status(:bad_request) }

    it 'raises a key decoding error' do
      expect_json('errors.0', /Invalid public_key/)
    end
  end

  context 'using a public key that does not match the token' do # rubocop:todo RSpec/ContextWording
    before do
      # rubocop:todo RSpec/InstanceVariable
      send(verb, @endpoint, attributes_for(@entity, :with_different_key)
                              # rubocop:enable RSpec/InstanceVariable
                              .merge(params))
    end

    it { expect_status(:bad_request) }

    it 'raises a key decoding error' do
      expect_json('errors.0', /JWT token failed verification/)
    end
  end
end
