require_relative 'shared_examples/auth'

RSpec.describe 'Organizations API' do
  let!(:organization1) { create(:organization, name: 'Stanford') }
  let!(:organization2) { create(:organization, name: 'MIT') }

  describe 'GET /metadata/organizations' do
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

  describe 'GET /metadata/organizations/:id' do
    context 'nonexistent CTID' do
      it 'returns 404' do
        get '/metadata/organizations/0'
        expect_status(:not_found)
      end
    end

    it 'returns organization with given CTID' do
      get "/metadata/organizations/#{organization1._ctid}"
      expect_status(:ok)
      expect_json('id', organization1.id)
      expect_json('_ctid', organization1._ctid)
      expect_json('description', organization1.description)
      expect_json('name', organization1.name)
    end
  end

  describe 'GET /metadata/organizations/:id/envelopes' do
    let!(:envelope1) { create(:envelope, organization: organization1) }
    let!(:envelope2) { create(:envelope, organization: organization1) }
    let!(:envelope3) { create(:envelope, organization: organization1) }
    let!(:envelope4) { create(:envelope, organization: organization2) }
    let!(:envelope5) { create(:envelope, organization: organization2) }

    context 'full' do
      it 'returns envelopes owned by the organization' do
        get "/metadata/organizations/#{organization1._ctid}/envelopes"
        expect_status(:ok)
        expect_json_sizes(3)
        expect_json('0.envelope_id', envelope1.envelope_id)
        expect_json('0.resource', envelope1.resource)
        expect_json(
          '0.decoded_resource',
          **envelope1
            .processed_resource
            .symbolize_keys
            .slice(:name, :description, :url)
        )
        expect_json('1.envelope_id', envelope2.envelope_id)
        expect_json(
          '1.decoded_resource',
          **envelope2
            .processed_resource
            .symbolize_keys
            .slice(:name, :description, :url)
        )
        expect_json('1.resource', envelope2.resource)
        expect_json('2.envelope_id', envelope3.envelope_id)
        expect_json('2.resource', envelope3.resource)
        expect_json(
          '2.decoded_resource',
          **envelope3
            .processed_resource
            .symbolize_keys
            .slice(:name, :description, :url)
        )

        get "/metadata/organizations/#{organization2._ctid}/envelopes"
        expect_status(:ok)
        expect_json_sizes(2)
        expect_json('0.envelope_id', envelope4.envelope_id)
        expect_json('0.resource', envelope4.resource)
        expect_json(
          '0.decoded_resource',
          **envelope4
            .processed_resource
            .symbolize_keys
            .slice(:name, :description, :url)
        )
        expect_json('1.envelope_id', envelope5.envelope_id)
        expect_json('1.resource', envelope5.resource)
        expect_json(
          '1.decoded_resource',
          **envelope5
            .processed_resource
            .symbolize_keys
            .slice(:name, :description, :url)
        )
      end
    end

    context 'metadata only' do
      it 'returns envelopes owned by the organization' do
        get "/metadata/organizations/#{organization1._ctid}/envelopes?metadata_only=true"

        expect_status(:ok)
        expect_json_sizes(3)
        expect_json('0.envelope_id', envelope1.envelope_id)
        expect_json('0.resource', nil)
        expect_json('0.decoded_resource', nil)
        expect_json('1.envelope_id', envelope2.envelope_id)
        expect_json('1.resource', nil)
        expect_json('1.decoded_resource', nil)
        expect_json('2.envelope_id', envelope3.envelope_id)
        expect_json('2.resource', nil)
        expect_json('2.decoded_resource', nil)

        get "/metadata/organizations/#{organization2._ctid}/envelopes?metadata_only=true"
        expect_status(:ok)
        expect_json_sizes(2)
        expect_json('0.envelope_id', envelope4.envelope_id)
        expect_json('0.resource', nil)
        expect_json('0.decoded_resource', nil)
        expect_json('1.envelope_id', envelope5.envelope_id)
        expect_json('1.resource', nil)
        expect_json('1.decoded_resource', nil)
      end
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
          organization = Organization.order(:created_at).last
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
    let(:organization_id) { organization._ctid }

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
          let(:organization) { envelope.organization }

          context 'with envelopes' do
            let(:envelope) do
              create(:envelope, organization: create(:organization))
            end

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
            let(:envelope) do
              create(:envelope, :deleted, organization: create(:organization))
            end

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
