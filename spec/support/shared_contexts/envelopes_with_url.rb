RSpec.shared_context 'envelopes with url' do
  let(:resource) do
    url ||= 'http://example.org/resource'
    jwt_encode(build(:resource, url: url))
  end

  let!(:envelopes) do
    [create(:envelope, resource: resource),
     create(:envelope, resource: resource)]
  end
end
