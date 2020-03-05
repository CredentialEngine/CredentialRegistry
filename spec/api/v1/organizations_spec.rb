require_relative 'shared_examples/auth'

RSpec.describe 'Organizations API' do
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
             {
               name: name,
               description: description
             },
             'Authorization' => "Token #{token.value}"
      end

      context 'empty name' do
        let(:name) {}

        it do
          expect_status(:unprocessable_entity)
          expect_json('error', "Name can't be blank")
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

  describe 'DELETE /metadata/organizations/:id' do
    let(:organization) { create(:organization) }
    let(:organization_id) { organization.id }

    include_examples 'requires auth',
                     :delete,
                     "/metadata/organizations/123"

    context 'authenticated' do
      before do
        delete "/metadata/organizations/#{organization_id}",
               nil,
               'Authorization' => "Token #{token.value}"
      end

      context 'as admin' do
        let(:token) { create(:auth_token, :admin) }

        context 'nonexistent organization' do
          let(:organization_id) { 'wtf' }

          it 'returns 404' do
            expect_status(:not_found)
          end
        end

        context 'existing organization' do
          context 'with envelopes' do
            let(:envelope) do
              create(:envelope, organization: create(:organization))
            end

            let(:organization) { envelope.organization }

            it "doesn't delete organization" do
              expect { organization.reload }.not_to raise_error
              expect_status(:unprocessable_entity)

              expect_json(
                'errors.0',
                "Organization has published resources, can't be removed"
              )
            end
          end

          context 'without envelopes' do
            it 'deletes organization' do
              expect { organization.reload }.to raise_error(
                ActiveRecord::RecordNotFound
              )

              expect_status(:no_content)
            end
          end
        end
      end

      context 'as publisher' do
        let(:token) { create(:auth_token) }

        it 'denies access' do
          expect_status(:forbidden)
        end
      end
    end
  end
end
