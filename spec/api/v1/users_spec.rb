require_relative 'shared_examples/auth'

RSpec.describe 'Users API' do # rubocop:todo RSpec/DescribeClass
  before do
    create(:envelope_community,
           name: 'ce_registry',
           default: true)
  end

  describe 'POST /metadata/publishers/:publisher_id/users' do
    include_examples 'requires auth', :post, '/metadata/publishers/0/users'

    context 'as admin' do # rubocop:todo RSpec/ContextWording
      let(:admin) { token.admin }
      let(:email) { Faker::Internet.email }
      let(:publisher) { create(:publisher, admin: admin) }
      let(:token) { create(:auth_token, :admin) }

      before do
        post "/metadata/publishers/#{publisher.id}/users",
             { email: email },
             'Authorization' => "Token #{token.value}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'empty email' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:email) {} # rubocop:todo Lint/EmptyBlock

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', "Email can't be blank")
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'existing email' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:email) { create(:user).email.upcase }

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', 'Email has already been taken')
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context "someone else's publisher" do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:publisher) { create(:publisher) }

        it do
          expect_status(:not_found)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'valid params' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it do
          user = User.last
          expect(user.publisher).to eq(publisher)
          expect(user.email).to eq(email)
          expect_status(:created)
          expect_json('id', user.id)
          expect_json('email', user.email)
        end
      end
    end

    context 'as publisher' do # rubocop:todo RSpec/ContextWording
      let(:token) { create(:auth_token) }

      it do
        post '/metadata/publishers/0/users',
             { email: '' },
             'Authorization' => "Token #{token.value}"
        expect_status(:forbidden)
      end
    end
  end
end
