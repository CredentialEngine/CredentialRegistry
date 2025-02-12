RSpec.shared_context 'envelopes with url' do # rubocop:todo RSpec/ContextWording
  let(:resource) do
    url ||= 'http://example.org/resource'
    jwt_encode(build(:resource, url: url))
  end

  let!(:envelopes) do # rubocop:todo RSpec/LetSetup
    Array.new(2) { create(:envelope, resource: resource) }
  end
end
