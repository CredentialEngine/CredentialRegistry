RSpec.shared_examples 'missing envelope' do |verb|
  before do
    @params = defined?(params) ? params : {}
  end

  context 'with non-existent envelope' do
    before do
      send(verb,
           '/learning-registry/envelopes/non-existent-envelope-id',
           @params) # rubocop:todo RSpec/InstanceVariable
    end

    it { expect_status(:not_found) }

    it 'returns the list of validation errors' do
      expect_json_keys(:errors)
      expect_json('errors.0', 'Couldn\'t find Envelope')
    end
  end

  context 'with envelope in different metadata community' do
    let(:credential) { create(:envelope, :from_cer) }

    before do
      send(verb,
           "/learning-registry/envelopes/#{credential.envelope_id}",
           @params) # rubocop:todo RSpec/InstanceVariable
    end

    it { expect_status(:not_found) }

    it 'returns the list of validation errors' do
      expect_json_keys(:errors)
      expect_json('errors.0', 'Couldn\'t find Envelope')
    end
  end
end
