RSpec.describe AuthToken do
  describe 'after_create' do
    it 'generates unique value' do
      existing_auth_token = create(:auth_token)
      value = Faker::Lorem.characters(number: 32)
      expect(SecureRandom).to receive(:hex)
        .and_return(existing_auth_token.value, value)
      auth_token = AuthToken.create!
      expect(auth_token.value).to eq(value)
    end
  end
end
