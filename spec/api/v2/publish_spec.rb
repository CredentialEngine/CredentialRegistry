RSpec.describe API::V2::Publish do
  let(:ctid) { envelope.envelope_ceterms_ctid }
  let(:organization) { create(:organization) }

  # rubocop:todo RSpec/LetSetup
  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  # rubocop:enable RSpec/LetSetup
  let!(:navy) { create(:envelope_community, name: 'navy') } # rubocop:todo RSpec/LetSetup

  describe 'POST /resources/organizations/:organization_id/documents' do
    let(:publishing_organization) { create(:organization) }

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:user) { create(:user) }
      let(:user2) { create(:user) }

      let(:resource_json) do
        File.read(
          MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
        )
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'publish on behalf without token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      # rubocop:todo RSpec/ContextWording
      context 'publish on behalf with token, can publish on behalf of organization' do
        # rubocop:enable RSpec/ContextWording
        # rubocop:enable RSpec/NestedGroups
        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)
          post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
               resource_json,
               {
                 'Accept-Version' => 'v2',
                 'Authorization' => "Token #{user.auth_token.value}"
               }
        end

        it 'schedules a publishing request' do
          expect_status(:ok)
          expect_json_keys(%i[id envelope_id envelope_ceterms_ctid created_at completed_at error])
          expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 1
          expect(ActiveJob::Base.queue_adapter.enqueued_jobs.first[:job]).to eq PublishEnvelopeJob
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
