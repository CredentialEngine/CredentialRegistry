RSpec.describe AuthToken do
  describe 'after_create' do
    it 'generates unique value' do
      existing_auth_token = create(:auth_token)
      value = Faker::Lorem.characters(number: 32)
      expect(SecureRandom).to receive(:hex) # rubocop:todo RSpec/MessageSpies
        .and_return(existing_auth_token.value, value)
      auth_token = described_class.create!
      expect(auth_token.value).to eq(value)
    end
  end
end
