RSpec.describe API::V2::Publish do
  let(:ctid) { envelope.envelope_ceterms_ctid }
  let(:organization) { create(:organization) }

  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  let!(:navy) { create(:envelope_community, name: 'navy') }

  describe 'POST /resources/organizations/:organization_id/documents' do
    let(:publishing_organization) { create(:organization) }

    context 'default community' do
      let(:user) { create(:user) }
      let(:user2) { create(:user) }

      let(:resource_json) do
        File.read(
          MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
        )
      end

      context 'publish on behalf without token' do
        before do
          post "/resources/organizations/#{organization._ctid}/documents",
               resource_json,
               {
                 'Accept-Version' => 'v2'
               }
        end

        it 'returns a 401 unauthorized http status code' do
          expect_status(:unauthorized)
        end
      end

      context 'publish on behalf with token, can publish on behalf of organization' do
        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)
          post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
              resource_json,
              {
                'Accept-Version' => 'v2',
                'Authorization' => 'Token ' + user.auth_token.value
              }
        end

        it 'schedules a publishing request' do
          expect_status(:ok)
          expect_json_keys(%i[id envelope_id envelope_ceterms_ctid created_at completed_at error])
          expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 1
          expect(ActiveJob::Base.queue_adapter.enqueued_jobs.first[:job]).to eq PublishEnvelopeJob
        end
      end
    end
  end
end
