require 'validate_api_key'

RSpec.describe ValidateApiKey do
  describe '.call' do
    let(:api_key) { Faker::Lorem.characters }
    let(:community) { create(:envelope_community) }
    let(:result) { described_class.call(api_key, community) }

    let(:request_stub) do
      stub_request(:get, ENV.fetch('API_KEY_VALIDATION_ENDPOINT', nil))
        .with(query: { apikey: api_key, community: community.name })
    end

    before do
      ENV['API_KEY_VALIDATION_ENDPOINT'] = Faker::Internet.url

      VCR.turn_off!
    end

    context 'error during validation' do # rubocop:todo RSpec/ContextWording
      before do
        request_stub.to_return(status: [404, 500].sample)
      end

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context 'invalid API key' do # rubocop:todo RSpec/ContextWording
      before do
        request_stub.to_return(body: { valid: false }.to_json)
      end

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context 'valid API key' do # rubocop:todo RSpec/ContextWording
      before do
        request_stub.to_return(body: { valid: true }.to_json)
      end

      it 'returns true' do
        expect(result).to be(true)
      end
    end
  end
end
