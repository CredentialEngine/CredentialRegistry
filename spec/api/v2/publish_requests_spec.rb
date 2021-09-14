RSpec.describe API::V2::PublishRequests do
  let(:ctid) { envelope.envelope_ceterms_ctid }
  let(:organization) { create(:organization) }

  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  let!(:navy) { create(:envelope_community, name: 'navy') }

  describe '/publish_requests' do
    let(:user) { create(:user) }
    let(:envelope_community) { create(:envelope_community) }
    let(:publish_requests) {
      create_list(:publish_request, 5, envelope_community: envelope_community)
    }
    before { publish_requests }

    context 'GET /' do
      it 'returns a paginated list of publish requests' do
        get "/publish_requests",
          {
            'Accept-Version' => 'v2',
            'Authorization' => 'Token ' + user.auth_token.value
          }
        expect_status(:ok)
        expect_json_types(:array)
        expect_json_sizes(5)
        expect_json('4.id', publish_requests.first.id)
      end
    end

    context 'GET /:id' do
      it 'returns a publish request' do
        get "/publish_requests/#{publish_requests.first.id}",
          {
            'Accept-Version' => 'v2',
            'Authorization' => 'Token ' + user.auth_token.value
          }
        expect_status(:ok)
        expect_json(id: publish_requests.first.id)
        expect_json(status: 'pending')
      end
    end
  end
end
