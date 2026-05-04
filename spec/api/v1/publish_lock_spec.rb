RSpec.describe API::V1::Publish do
  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:resource_json) do
    File.read(
      MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
    )
  end

  before do
    create(:organization_publisher, organization:, publisher: user.publisher)
    RegistryChangesetSync.create!(
      envelope_community: ce_registry,
      last_activity_at: Time.current,
      syncing: true,
      syncing_started_at: Time.current
    )
  end

  it 'rejects publish while S3 sync is in progress' do
    post "/resources/organizations/#{organization._ctid}/documents",
         resource_json,
         'Authorization' => "Token #{user.auth_token.value}"

    expect_status(503)
    expect_json('errors.0', RegistryChangesetSync::PUBLISH_LOCKED)
  end
end
