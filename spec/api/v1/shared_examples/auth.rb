RSpec.shared_examples 'requires auth' do |verb, path|
  context 'no header' do # rubocop:todo RSpec/ContextWording
    it 'returns 401' do
      send(verb, path, nil)
      expect_status(:unauthorized)
      expect_json('errors.0', 'Invalid token')
    end
  end

  context 'empty header' do # rubocop:todo RSpec/ContextWording
    it 'returns 401' do
      send(verb, path, nil, 'Authorization' => '')
      expect_status(:unauthorized)
      expect_json('errors.0', 'Invalid token')
    end
  end

  context 'nonexistent token' do # rubocop:todo RSpec/ContextWording
    it 'returns 401' do
      send(verb, path, nil, 'Authorization' => 'Token wtf')
      expect_status(:unauthorized)
      expect_json('errors.0', 'Invalid token')
    end
  end
end
