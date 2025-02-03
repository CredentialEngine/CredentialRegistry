require 'open3'
require 'spec_helper'

# rubocop:todo RSpec/MultipleMemoizedHelpers
RSpec.describe 'app:generate_auth_token' do # rubocop:todo RSpec/DescribeClass, RSpec/MultipleMemoizedHelpers
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

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'missing variables' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'ADMIN_NAME' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:admin_name) { nil }

      it 'returns error' do
        expect { result }.not_to change(AuthToken, :count)
        expect(error).to eq("Missing or empty variables: ADMIN_NAME\n")
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'PUBLISHER_NAME' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:publisher_name) { nil }

      it 'returns error' do
        expect { result }.not_to change(AuthToken, :count)
        expect(error).to eq("Missing or empty variables: PUBLISHER_NAME\n")
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'USER_EMAIL' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:user_email) { nil }

      it 'returns error' do
        expect { result }.not_to change(AuthToken, :count)
        expect(error).to eq("Missing or empty variables: USER_EMAIL\n")
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'existing user', :broken do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let!(:admin) { create(:admin, name: admin_name) }
    let!(:publisher) { create(:publisher, admin:, name: publisher_name) }
    let!(:user) { create(:user, admin:, email: user_email, publisher:) }

    it 'generates auth token' do
      p [:start]
      expect { result }.to change(AuthToken, :count).by(1)
                                                    .and not_change { Admin.count }
        .and not_change { Publisher.count }
        .and not_change { User.count }

      auth_token = AuthToken.last
      expect(auth_token.value).to eq(token)
      expect(auth_token.user).to eq(user)
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'new user' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    # rubocop:todo RSpec/MultipleExpectations
    it 'generates auth token' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      # rubocop:enable RSpec/MultipleExpectations
      expect { result }.to change(Admin, :count).by(1)
                                                .and change(AuthToken, :count).by(1)
                                                                              .and change(
                                                                                Publisher, :count
                                                                              ).by(1)
        .and change(
          User, :count
        ).by(1)

      admin = Admin.last
      expect(admin.name).to eq(admin_name)

      publisher = Publisher.last
      expect(publisher.admin).to eq(admin)
      expect(publisher.name).to eq(publisher_name)
      expect(publisher.super_publisher?).to be(true)

      user = User.last
      expect(user.admin).to eq(admin)
      expect(user.email).to eq(user_email)
      expect(user.publisher).to eq(publisher)

      auth_token = AuthToken.last
      expect(auth_token.value).to eq(token)
      expect(auth_token.user).to eq(user)
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
