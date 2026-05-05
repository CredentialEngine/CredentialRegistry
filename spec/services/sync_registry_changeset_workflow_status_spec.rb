require 'sync_registry_changeset_workflow_status'

RSpec.describe SyncRegistryChangesetWorkflowStatus do
  let(:api_error_class) do
    Class.new(StandardError) do
      attr_reader :code

      def initialize(code, message)
        @code = code
        super(message)
      end
    end
  end
  let(:client) { instance_double(ArgoWorkflowsClient) }
  let(:envelope_community) { create(:envelope_community, name: 'ce_registry') }
  let(:version) do
    EnvelopeVersion.create!(
      item_type: 'Envelope',
      item_id: 1,
      event: 'create',
      envelope_community_id: envelope_community.id,
      envelope_ceterms_ctid: 'ce-123',
      created_at: Time.current
    )
  end
  let(:sync) do
    RegistryChangesetSync.create!(
      envelope_community:,
      last_activity_at: Time.current,
      last_activity_version_id: version.id,
      syncing: true,
      syncing_started_at: Time.current,
      argo_workflows: [
        {
          'entity_type' => 'graphs',
          'manifest_key' => 'ce_registry/changesets/manifests/graphs-2026.gz',
          'name' => 'ce-registry-apply-changeset-graphs-abc123',
          'namespace' => 'credreg-staging'
        }
      ]
    )
  end

  before do
    stub_const('ArgoWorkflowsApiClient::ApiError', api_error_class)
    allow(ArgoWorkflowsClient).to receive(:new).and_return(client)
  end

  it 'keeps the sync locked while the workflow is running' do
    allow(client).to receive(:get_workflow)
      .with(name: 'ce-registry-apply-changeset-graphs-abc123')
      .and_return(status: { phase: 'Running' })

    described_class.call(sync:)

    sync.reload
    expect(sync.syncing).to be(true)
    expect(sync.argo_workflows).not_to be_empty
    expect(sync.last_synced_version_id).to be_nil
  end

  it 'marks the sync complete when every workflow succeeds' do
    allow(client).to receive(:get_workflow)
      .with(name: 'ce-registry-apply-changeset-graphs-abc123')
      .and_return(status: { phase: 'Succeeded' })

    described_class.call(sync:)

    sync.reload
    expect(sync.syncing).to be(false)
    expect(sync.argo_workflows).to eq([])
    expect(sync.last_synced_version_id).to eq(version.id)
    expect(sync.last_sync_finished_at).to be_present
    expect(sync.last_sync_error).to be_nil
  end

  it 'marks the sync failed and unlocks when a workflow fails' do
    allow(client).to receive(:get_workflow)
      .with(name: 'ce-registry-apply-changeset-graphs-abc123')
      .and_return(status: { phase: 'Failed', message: 'apply failed' })

    described_class.call(sync:)

    sync.reload
    expect(sync.syncing).to be(false)
    expect(sync.argo_workflows).to eq([])
    expect(sync.last_synced_version_id).to be_nil
    expect(sync.last_sync_error).to eq('StandardError: apply failed')
  end

  it 'marks the sync failed and unlocks when the workflow is missing in Argo' do
    allow(client).to receive(:get_workflow)
      .with(name: 'ce-registry-apply-changeset-graphs-abc123')
      .and_raise(ArgoWorkflowsApiClient::ApiError.new(404, 'Not Found'))

    described_class.call(sync:)

    sync.reload
    expect(sync.syncing).to be(false)
    expect(sync.argo_workflows).to eq([])
    expect(sync.last_synced_version_id).to be_nil
    expect(sync.last_sync_error).to eq(
      'StandardError: Argo workflow ce-registry-apply-changeset-graphs-abc123 not found: Not Found'
    )
  end

  it 'keeps the sync locked on transient Argo lookup errors' do
    allow(client).to receive(:get_workflow)
      .with(name: 'ce-registry-apply-changeset-graphs-abc123')
      .and_raise(ArgoWorkflowsApiClient::ApiError.new(500, 'Internal Server Error'))
    allow(MR.logger).to receive(:warn)

    described_class.call(sync:)

    sync.reload
    expect(sync.syncing).to be(true)
    expect(sync.argo_workflows).not_to be_empty
    expect(sync.last_synced_version_id).to be_nil
  end
end
