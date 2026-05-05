require 'sync_pending_registry_changesets'
require 'rubygems/package'

RSpec.describe SyncPendingRegistryChangesets do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:envelope_community) { create(:envelope_community, name: 'ce_registry') }
  let(:cutoff_version_id) { @cutoff_version_id }
  let(:cutoff_resource_event_id) { EnvelopeResourceSyncEvent.maximum(:id) }
  let(:sync) do
    RegistryChangesetSync.find_or_initialize_by(envelope_community: envelope_community).tap do |record|
      record.last_activity_at = Time.current
      record.last_activity_version_id = cutoff_version_id
      record.last_activity_resource_event_id = cutoff_resource_event_id
      record.last_synced_version_id = nil
      record.last_synced_resource_event_id = nil
      record.scheduled_for_at = nil
      record.syncing = false
      record.syncing_started_at = nil
      record.last_sync_finished_at = nil
      record.last_sync_error = nil
      record.argo_workflows = []
      record.save!
    end
  end
  let(:service) do
    described_class.new(
      envelope_community: envelope_community,
      cutoff_version_id: cutoff_version_id,
      cutoff_resource_event_id: cutoff_resource_event_id,
      sync: sync
    )
  end
  let(:s3_bucket) { double('s3_bucket') } # rubocop:todo RSpec/VerifiedDoubles
  let(:s3_bucket_name) { Faker::Lorem.word }
  let(:s3_resource) { double('s3_resource') } # rubocop:todo RSpec/VerifiedDoubles
  let(:uploaded_objects) { {} }
  let(:argo_workflow) { { metadata: { name: 'ce-registry-apply-changeset-graphs-abc123' } } }
  let(:upload_envelope) { @upload_envelope }
  let(:delete_envelope) { @delete_envelope }
  let(:upload_resource_record) { @upload_resource_record }
  let(:delete_resource_id) { @delete_resource_id }
  let(:graph_upload_key) do
    "#{envelope_community.name}/graphs/#{upload_envelope.envelope_ceterms_ctid}.json"
  end
  let(:graph_delete_key) do
    "#{envelope_community.name}/graphs/#{delete_envelope.envelope_ceterms_ctid}.json"
  end
  let(:resource_upload_key) do
    "#{envelope_community.name}/resources/#{upload_resource_record.resource_id.downcase}.json"
  end
  let(:resource_delete_key) do
    "#{envelope_community.name}/resources/#{delete_resource_id.downcase}.json"
  end

  before do
    with_versioning do
      @upload_envelope = create(:envelope, :from_cer, envelope_community: envelope_community)
      @delete_envelope = create(:envelope, :from_cer, envelope_community: envelope_community)
      @delete_envelope.destroy
    end
    @upload_resource_record = create(
      :envelope_resource,
      envelope: upload_envelope,
      resource_id: 'ce-11111111-1111-1111-1111-111111111111',
      processed_resource: {
        '@id' => 'https://example.org/resources/alpha',
        '@type' => 'ceterms:Credential',
        'ceterms:ctid' => 'ce-11111111-1111-1111-1111-111111111111'
      }
    )
    @delete_resource_id = 'ce-22222222-2222-2222-2222-222222222222'
    EnvelopeResourceSyncEvent.create!(
      envelope_community: envelope_community,
      resource_id: upload_resource_record.resource_id,
      action: EnvelopeResourceSyncEvent::ACTIONS[:upsert]
    )
    EnvelopeResourceSyncEvent.create!(
      envelope_community: envelope_community,
      resource_id: delete_resource_id,
      action: EnvelopeResourceSyncEvent::ACTIONS[:delete]
    )
    @cutoff_version_id = EnvelopeVersion.maximum(:id)

    ENV['AWS_REGION'] = 'us-east-1'
    ENV['ENVELOPE_GRAPHS_BUCKET'] = s3_bucket_name

    allow(Aws::S3::Resource).to receive(:new).with(region: 'us-east-1').and_return(s3_resource)
    allow(s3_resource).to receive(:bucket).with(s3_bucket_name).and_return(s3_bucket)
    allow(s3_bucket).to receive(:object) do |key|
      object = double("s3_object:#{key}") # rubocop:todo RSpec/VerifiedDoubles
      allow(object).to receive(:put) { |args| uploaded_objects[key] = args }
      object
    end
    allow(SubmitChangesetWorkflow).to receive(:call).and_return(argo_workflow)
  end

  it 'uploads graph, metadata, and resource changesets with manifests' do
    service.call

    expect(uploaded_objects.keys).to include(
      match(%r{\Ace_registry/changesets/graphs/.+\.tar\.gz\z}),
      match(%r{\Ace_registry/changesets/metadata/.+\.tar\.gz\z}),
      match(%r{\Ace_registry/changesets/resources/.+\.tar\.gz\z}),
      match(%r{\Ace_registry/changesets/manifests/graphs-.+\.gz\z}),
      match(%r{\Ace_registry/changesets/manifests/metadata-.+\.gz\z}),
      match(%r{\Ace_registry/changesets/manifests/resources-.+\.gz\z})
    )
    expect(SubmitChangesetWorkflow).to have_received(:call).with(
      envelope_community:,
      entity_type: :graphs,
      manifest_key: match(%r{\Ace_registry/changesets/manifests/graphs-.+\.gz\z})
    )
    sync.reload
    expect(sync.last_synced_version_id).to be_nil
    expect(sync.last_synced_resource_event_id).to be_nil
    expect(sync.argo_workflows).to contain_exactly(
      include('entity_type' => 'graphs', 'name' => 'ce-registry-apply-changeset-graphs-abc123'),
      include('entity_type' => 'metadata', 'name' => 'ce-registry-apply-changeset-graphs-abc123'),
      include('entity_type' => 'resources', 'name' => 'ce-registry-apply-changeset-graphs-abc123')
    )
  end

  it 'writes a graph manifest pointing at the graph changeset' do
    service.call

    manifest_key = uploaded_objects.keys.find do |key|
      key.match?(%r{\Ace_registry/changesets/manifests/graphs-.+\.gz\z})
    end
    manifest = uploaded_json(manifest_key)

    expect(manifest).to include(
      'bucket' => s3_bucket_name,
      'entity_type' => 'graphs',
      'changeset_key' => match(%r{\Ace_registry/changesets/graphs/.+\.tar\.gz\z})
    )
    expect(manifest['upserts']).to eq(
      [
        {
          'envelope_ceterms_ctid' => upload_envelope.envelope_ceterms_ctid,
          'key' => graph_upload_key,
          'updated_at' => upload_envelope.versions.last.created_at.iso8601
        }
      ]
    )
    expect(manifest['deletes']).to eq(
      [
        {
          'envelope_ceterms_ctid' => delete_envelope.envelope_ceterms_ctid,
          'key' => graph_delete_key,
          'updated_at' => delete_envelope.versions.last.created_at.iso8601
        }
      ]
    )
  end

  it 'writes graph documents into the graph changeset' do
    service.call

    changeset = uploaded_archive_entries(%r{\Ace_registry/changesets/graphs/.+\.tar\.gz\z})

    expect(changeset.keys).to eq([graph_upload_key])
    expect(changeset.fetch(graph_upload_key)).to eq(upload_envelope.processed_resource)
  end

  it 'writes resource documents into the resource changeset' do
    service.call

    changeset = uploaded_archive_entries(%r{\Ace_registry/changesets/resources/.+\.tar\.gz\z})

    expect(changeset.keys).to include(resource_upload_key)
    expect(changeset.fetch(resource_upload_key)).to eq(
      upload_resource_record.processed_resource.merge(
        '@context' => upload_envelope.processed_resource['@context']
      )
    )
  end

  it 'writes metadata documents into the metadata changeset' do
    service.call

    changeset = uploaded_archive_entries(%r{\Ace_registry/changesets/metadata/.+\.tar\.gz\z})
    document = changeset.fetch("#{envelope_community.name}/metadata/#{upload_envelope.envelope_ceterms_ctid}.json")

    expect(document).to include(
      'envelope_community' => envelope_community.name,
      'envelope_id' => upload_envelope.envelope_id,
      'envelope_ceterms_ctid' => upload_envelope.envelope_ceterms_ctid,
      'envelope_ctdl_type' => upload_envelope.envelope_ctdl_type,
      'envelope_type' => upload_envelope.envelope_type,
      'envelope_version' => upload_envelope.envelope_version,
      'publisher_id' => upload_envelope.publisher_id,
      'secondary_publisher_id' => upload_envelope.secondary_publisher_id,
      'resource_publish_type' => upload_envelope.resource_publish_type,
      'owned_by' => upload_envelope.organization&._ctid,
      'published_by' => upload_envelope.publishing_organization&._ctid,
      'changed' => false
    )
    expect(document).to have_key('node_headers')
    expect(document).not_to have_key('decoded_resource')
    expect(document).not_to have_key('resource_format')
    expect(document).not_to have_key('resource_encoding')
  end

  it 'leaves versions newer than the cutoff for the next batch' do
    with_versioning do
      upload_envelope.update!(envelope_version: '2.0.0')
    end

    service.call

    changeset = uploaded_archive_entries(%r{\Ace_registry/changesets/graphs/.+\.tar\.gz\z})

    expect(changeset).to be_empty
    expect(sync.reload.last_synced_version_id).to be_nil
  end

  it 'syncs only the latest pending version for each CTID' do
    with_versioning do
      upload_envelope.update!(envelope_version: '2.0.0')
    end
    @cutoff_version_id = EnvelopeVersion.maximum(:id)

    service.call

    changeset = uploaded_archive_entries(%r{\Ace_registry/changesets/graphs/.+\.tar\.gz\z})

    expect(changeset.size).to eq(1)
  end

  it 'writes changesets and calls argo for delete-only batches' do
    sync.update!(last_synced_version_id: upload_envelope.versions.last.id)
    sync.update!(
      last_synced_resource_event_id: EnvelopeResourceSyncEvent
        .find_by!(resource_id: upload_resource_record.resource_id).id
    )

    service.call

    graph_manifest_key = uploaded_objects.keys.find do |key|
      key.match?(%r{\Ace_registry/changesets/manifests/graphs-.+\.gz\z})
    end
    resource_manifest_key = uploaded_objects.keys.find do |key|
      key.match?(%r{\Ace_registry/changesets/manifests/resources-.+\.gz\z})
    end

    expect(uploaded_json(graph_manifest_key)['deletes']).not_to be_empty
    expect(uploaded_json(resource_manifest_key)['deletes']).not_to be_empty
    expect(SubmitChangesetWorkflow).to have_received(:call).at_least(:once)
  end

  it 'passes argo the same graph manifest key that it uploads' do
    submitted_manifest_key = nil

    allow(SubmitChangesetWorkflow).to receive(:call) do |envelope_community:, entity_type:, manifest_key:|
      next argo_workflow unless entity_type == :graphs

      submitted_manifest_key = manifest_key
      argo_workflow
    end

    service.call

    expect(uploaded_objects).to have_key(submitted_manifest_key)
  end

  it 'skips non-CTID resource events' do
    EnvelopeResourceSyncEvent.create!(
      envelope_community: envelope_community,
      resource_id: 'https://example.org/resources/not-a-ctid',
      action: EnvelopeResourceSyncEvent::ACTIONS[:upsert]
    )
    sync.update!(last_synced_resource_event_id: nil)

    service.call

    changeset = uploaded_archive_entries(%r{\Ace_registry/changesets/resources/.+\.tar\.gz\z})

    expect(changeset.to_json).not_to include('https://example.org/resources/not-a-ctid')
  end

  def uploaded_json(key)
    payload = uploaded_objects.fetch(key)

    expect(payload.fetch(:content_encoding)).to eq('gzip')
    expect(payload.fetch(:content_type)).to eq('application/json')

    JSON.parse(Zlib::GzipReader.new(StringIO.new(payload.fetch(:body))).read)
  end

  def uploaded_archive_entries(pattern)
    key = uploaded_objects.keys.find { |uploaded_key| uploaded_key.match?(pattern) }
    payload = uploaded_objects.fetch(key)

    expect(payload.fetch(:content_encoding)).to eq('gzip')
    expect(payload.fetch(:content_type)).to eq('application/x-tar')

    entries = {}
    Zlib::GzipReader.wrap(StringIO.new(payload.fetch(:body))) do |gzip|
      Gem::Package::TarReader.new(gzip) do |tar|
        tar.each do |entry|
          entries[entry.full_name] = JSON.parse(entry.read)
        end
      end
    end
    entries
  end
end
