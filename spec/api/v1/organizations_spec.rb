require_relative 'shared_examples/auth'

describe 'Organizations API' do
  describe 'GET /metadata/organizations' do
    let!(:organization1) { create(:organization, name: 'Stanford') }
    let!(:organization2) { create(:organization, name: 'MIT') }

    it do
      get '/metadata/organizations'
      expect_status(:ok)
      expect_json('0.id', organization2.id)
      expect_json('0.description', organization2.description)
      expect_json('0.name', organization2.name)
      expect_json('1.id', organization1.id)
      expect_json('1.description', organization1.description)
      expect_json('1.name', organization1.name)
    end
  end

  describe 'POST /metadata/organizations' do
    include_examples 'requires auth', :post, '/metadata/organizations'

    context 'as admin' do
      let(:admin) { token.admin }
      let(:description) { Faker::Lorem.sentence }
      let(:name) { Faker::Company.name }
      let(:token) { create(:auth_token, :admin) }

      before do
        post '/metadata/organizations',
             { description: description, name: name },
             'Authorization' => "Token #{token.value}"
      end

      context 'empty name' do
        let(:name) {}

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', "Name can't be blank")
        end
      end

      context 'existing name' do
        let(:name) { create(:organization).name.upcase }

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', 'Name has already been taken')
        end
      end

      context 'valid params' do
        it do
          organization = Organization.last
          expect(organization.admin).to eq(admin)
          expect(organization.description).to eq(description)
          expect(organization.name).to eq(name)
          expect_status(:created)
          expect_json('id', organization.id)
          expect_json('description', organization.description)
          expect_json('name', organization.name)
        end
      end
    end

    context 'as publisher' do
      let(:token) { create(:auth_token) }

      it do
        post '/metadata/organizations',
             { name: '' },
             'Authorization' => "Token #{token.value}"
        expect_status(:forbidden)
      end
    end
  end
end
