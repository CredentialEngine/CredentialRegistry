RSpec.describe User do
  describe 'after_create' do
    it 'creates auth token' do
      user = User.new(
        email: Faker::Internet.email,
        publisher: create(:publisher)
      )
      expect { user.save! }.to change { user.auth_tokens.count }.by(1)
      expect { user.save! }.not_to change { user.auth_tokens.count }
    end
  end
end
