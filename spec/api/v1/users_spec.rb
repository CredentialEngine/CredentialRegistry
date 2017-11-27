require_relative 'shared_examples/auth'

describe 'Users API' do
  describe 'POST /metadata/publishers/:publisher_id/users' do
    include_examples 'requires auth', :post, '/metadata/publishers/0/users'

    context 'as admin' do
      let(:admin) { token.admin }
      let(:email) { Faker::Internet.email }
      let(:publisher) { create(:publisher, admin: admin) }
      let(:token) { create(:auth_token, :admin) }

      before do
        post "/metadata/publishers/#{publisher.id}/users",
             { email: email },
             'Authorization' => "Token #{token.value}"
      end

      context 'empty email' do
        let(:email) {}

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', "Email can't be blank")
        end
      end

      context 'existing email' do
        let(:email) { create(:user).email.upcase }

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', 'Email has already been taken')
        end
      end

      context "someone else's publisher" do
        let(:publisher) { create(:publisher) }

        it do
          expect_status(:not_found)
        end
      end

      context 'valid params' do
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

    context 'as publisher' do
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
