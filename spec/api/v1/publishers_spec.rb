require_relative 'shared_examples/auth'

RSpec.describe 'Publishers API' do # rubocop:todo RSpec/DescribeClass
  describe 'GET /metadata/publishers' do
    let!(:publisher1) { create(:publisher, name: 'Credly') } # rubocop:todo RSpec/IndexedLet
    let!(:publisher2) { create(:publisher, name: 'Shmedly') } # rubocop:todo RSpec/IndexedLet

    it do
      get '/metadata/publishers'
      expect_status(:ok)
      expect_json('0.id', publisher1.id)
      expect_json('0.contact_info', publisher1.contact_info)
      expect_json('0.description', publisher1.description)
      expect_json('0.name', publisher1.name)
      expect_json('1.id', publisher2.id)
      expect_json('1.contact_info', publisher2.contact_info)
      expect_json('1.description', publisher2.description)
      expect_json('1.name', publisher2.name)
    end
  end

  describe 'POST /metadata/publishers' do
    include_examples 'requires auth', :post, '/metadata/publishers'

    context 'as admin' do # rubocop:todo RSpec/ContextWording
      let(:admin) { token.admin }
      let(:contact_info) { Faker::Lorem.paragraph }
      let(:description) { Faker::Lorem.sentence }
      let(:name) { Faker::Company.name }
      let(:token) { create(:auth_token, :admin) }

      before do
        post '/metadata/publishers',
             {
               contact_info: contact_info,
               description: description,
               name: name
             },
             'Authorization' => "Token #{token.value}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'empty name' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:name) {} # rubocop:todo Lint/EmptyBlock

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', "Name can't be blank")
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'existing name' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:name) { create(:publisher).name.upcase }

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', 'Name has already been taken')
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'valid params' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it do # rubocop:todo RSpec/MultipleExpectations
          publisher = Publisher.last
          expect(publisher.admin).to eq(admin)
          expect(publisher.contact_info).to eq(contact_info)
          expect(publisher.description).to eq(description)
          expect(publisher.name).to eq(name)
          expect_status(:created)
          expect_json('id', publisher.id)
          expect_json('contact_info', publisher.contact_info)
          expect_json('description', publisher.description)
          expect_json('name', publisher.name)
        end
      end
    end

    context 'as publisher' do # rubocop:todo RSpec/ContextWording
      let(:token) { create(:auth_token) }

      it do
        post '/metadata/publishers',
             { name: '' },
             'Authorization' => "Token #{token.value}"
        expect_status(:forbidden)
      end
    end
  end
end
