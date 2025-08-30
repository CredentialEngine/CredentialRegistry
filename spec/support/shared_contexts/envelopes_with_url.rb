RSpec.shared_context 'envelopes with url' do # rubocop:todo RSpec/ContextWording
  let(:processed_resource) do
    url ||= 'http://example.org/resource'
    build(:resource, url: url)
  end

  let!(:envelopes) do # rubocop:todo RSpec/LetSetup
    Array.new(2) { create(:envelope, processed_resource:) }
  end
end
