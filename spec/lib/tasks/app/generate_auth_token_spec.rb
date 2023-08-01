require 'open3'
require 'spec_helper'

RSpec.describe 'app:generate_auth_token' do
  let(:admin_name) { Faker::Name.name }
  let(:error) { result[1] }
  let(:publisher_name) { Faker::Name.name }
  let(:token) { result[0]&.chomp }
  let(:user_email) { Faker::Internet.email }

  let(:result) do
    Open3.capture3(
      "ADMIN_NAME='#{admin_name}' " \
      "PUBLISHER_NAME='#{publisher_name}' " \
      "USER_EMAIL='#{user_email}' " \
      'bin/rake app:generate_auth_token'
    )
  end

  context 'missing variables' do
    context 'ADMIN_NAME' do
      let(:admin_name) { nil }

      it 'returns error' do
        expect { result }.not_to change { AuthToken.count }
        expect(error).to eq("Missing or empty variables: ADMIN_NAME\n")
      end
    end

    context 'PUBLISHER_NAME' do
      let(:publisher_name) { nil }

      it 'returns error' do
        expect { result }.not_to change { AuthToken.count }
        expect(error).to eq("Missing or empty variables: PUBLISHER_NAME\n")
      end
    end

    context 'USER_EMAIL' do
      let(:user_email) { nil }

      it 'returns error' do
        expect { result }.not_to change { AuthToken.count }
        expect(error).to eq("Missing or empty variables: USER_EMAIL\n")
      end
    end
  end

  context 'existing user', :broken do
    let!(:admin) { create(:admin, name: admin_name) }
    let!(:publisher) { create(:publisher, admin:, name: publisher_name) }
    let!(:user) { create(:user, admin:, email: user_email, publisher:) }

    it 'generates auth token' do
      p [:start]
      expect { result }.to change { AuthToken.count }.by(1)
      .and not_change { Admin.count }
      .and not_change { Publisher.count }
      .and not_change { User.count }

      auth_token = AuthToken.last
      expect(auth_token.value).to eq(token)
      expect(auth_token.user).to eq(user)
    end
  end

  context 'new user' do
    it 'generates auth token' do
      expect { result }.to change { Admin.count }.by(1)
      .and change { AuthToken.count }.by(1)
      .and change { Publisher.count }.by(1)
      .and change { User.count }.by(1)

      admin = Admin.last
      expect(admin.name).to eq(admin_name)

      publisher = Publisher.last
      expect(publisher.admin).to eq(admin)
      expect(publisher.name).to eq(publisher_name)
      expect(publisher.super_publisher?).to eq(true)

      user = User.last
      expect(user.admin).to eq(admin)
      expect(user.email).to eq(user_email)
      expect(user.publisher).to eq(publisher)

      auth_token = AuthToken.last
      expect(auth_token.value).to eq(token)
      expect(auth_token.user).to eq(user)
    end
  end
end
