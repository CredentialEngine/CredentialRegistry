RSpec.describe API::V2::PublishRequests do
  let(:ctid) { envelope.envelope_ceterms_ctid }
  let(:organization) { create(:organization) }

  # rubocop:todo RSpec/LetSetup
  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  # rubocop:enable RSpec/LetSetup
  let!(:navy) { create(:envelope_community, name: 'navy') } # rubocop:todo RSpec/LetSetup

  describe '/publish_requests' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let(:user) { create(:user) }
    let(:envelope_community) { create(:envelope_community) }
    let(:publish_requests) do
      create_list(:publish_request, 5, envelope_community: envelope_community)
    end

    before { publish_requests }

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'GET /' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      it 'returns a paginated list of publish requests' do
        get '/publish_requests',
            {
              'Accept-Version' => 'v2',
              'Authorization' => "Token #{user.auth_token.value}"
            }
        expect_status(:ok)
        expect_json_types(:array)
        expect_json_sizes(5)
        expect_json('4.id', publish_requests.first.id)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'GET /:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      it 'returns a publish request' do
        get "/publish_requests/#{publish_requests.first.id}",
            {
              'Accept-Version' => 'v2',
              'Authorization' => "Token #{user.auth_token.value}"
            }
        expect_status(:ok)
        expect_json(id: publish_requests.first.id)
        expect_json(status: 'pending')
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
