require 'spec_helper'

describe API::V1::Gremlin, :vcr do
  context 'POST /' do
    let(:token) { create(:auth_token, :admin) }
    let(:query) do
      {
        gremlin: 'g.V().count()'
      }.to_json
    end

    it 'proxies a request to Gremlin' do
      post '/gremlin', query, 'Authorization' => "Token #{token.value}"
      expect_status(:ok)
      expect_json_keys([:requestId, :result, :status])
    end
  end
end
