RSpec.shared_examples 'requires auth' do |verb, path|
  context 'no header' do
    it 'returns 401' do
      send(verb, path, nil)
      expect_status(:unauthorized)
      expect_json('errors.0', '401 Unauthorized')
    end
  end

  context 'empty header' do
    it 'returns 401' do
      send(verb, path, nil, 'Authorization' => '')
      expect_status(:unauthorized)
      expect_json('errors.0', '401 Unauthorized')
    end
  end

  context 'nonexistent token' do
    it 'returns 401' do
      send(verb, path, nil, 'Authorization' => 'Token wtf')
      expect_status(:unauthorized)
      expect_json('errors.0', '401 Unauthorized')
    end
  end
end
