require 'sync_pending_registry_changesets'

RSpec.describe SyncPendingRegistryChangesets do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:envelope_community) { create(:envelope_community, name: 'ce_registry') }
  let(:sync) do
    RegistryChangesetSync.find_or_initialize_by(envelope_community: envelope_community).tap do |record|
      record.update!(
        last_activity_at: Time.current,
        last_activity_version_id: cutoff_version_id,
        last_activity_resource_event_id: cutoff_resource_event_id,
        last_synced_version_id: nil,
        last_synced_resource_event_id: nil
      )
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
  let(:s3_resource) { double('s3_resource') } # rubocop:todo RSpec/VerifiedDoubles
  let(:uploaded_objects) { {} }
  let(:endpoint_response) { instance_double(Net::HTTPSuccess, code: '202') }
  let(:http_client) { instance_double(Net::HTTP) }
  let(:cutoff_version_id) { @cutoff_version_id }
  let(:cutoff_resource_event_id) { @cutoff_resource_event_id }

  before do
    with_versioning do
      @upload_envelope = create(:envelope, :from_cer, envelope_community: envelope_community)
      @delete_envelope = create(:envelope, :from_cer, envelope_community: envelope_community)
      @delete_envelope.destroy
    end

    @upload_resource = create(
      :envelope_resource,
      envelope: @upload_envelope,
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
      resource_id: @upload_resource.resource_id,
      action: EnvelopeResourceSyncEvent::ACTIONS[:upsert]
    )
    EnvelopeResourceSyncEvent.create!(
      envelope_community: envelope_community,
      resource_id: @delete_resource_id,
      action: EnvelopeResourceSyncEvent::ACTIONS[:delete]
    )

    @cutoff_version_id = EnvelopeVersion.maximum(:id)
    @cutoff_resource_event_id = EnvelopeResourceSyncEvent.maximum(:id)

    ENV['AWS_REGION'] = 'us-east-1'
    ENV['REGISTRY_CHANGESET_SYNC_BUCKET'] = 'changesets'
    ENV['REGISTRY_CHANGESET_SYNC_ENDPOINT'] = 'https://receiver.example.test/registry/changesets'

    allow(Aws::S3::Resource).to receive(:new).with(region: 'us-east-1').and_return(s3_resource)
    allow(s3_resource).to receive(:bucket).with('changesets').and_return(s3_bucket)
    allow(Net::HTTP).to receive(:start).and_yield(http_client)
    allow(http_client).to receive(:request).and_return(endpoint_response)
    allow(endpoint_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

    allow(s3_bucket).to receive(:object) do |key|
      object = double("s3_object:#{key}") # rubocop:todo RSpec/VerifiedDoubles
      allow(object).to receive(:put) { |args| uploaded_objects[key] = args }
      object
    end
  end

  after do
    ENV.delete('REGISTRY_CHANGESET_SYNC_BUCKET')
    ENV.delete('REGISTRY_CHANGESET_SYNC_ENDPOINT')
  end

  it 'uploads exactly one ZIP for the completed debounce window' do
    service.call

    expect(uploaded_objects.keys).to contain_exactly(
      match(%r{\Ace_registry/changesets/.+\.zip\z})
    )
    expect(uploaded_objects.values.first.fetch(:content_type)).to eq('application/zip')
  end


  it 'posts the generated ZIP to the configured endpoint' do
    service.call

    expect(Net::HTTP).to have_received(:start).with(
      'receiver.example.test',
      443,
      use_ssl: true,
      open_timeout: 30,
      read_timeout: 30
    )
    expect(http_client).to have_received(:request) do |request|
      uploaded_zip = uploaded_objects.values.first.fetch(:body)

      expect(request).to be_a(Net::HTTP::Post)
      expect(request.path).to eq('/registry/changesets')
      expect(request['Content-Type']).to eq('application/zip')
      expect(request['X-Registry-Community']).to eq('ce_registry')
      expect(request['X-Registry-Changeset-Key']).to match(
        %r{\Ace_registry/changesets/.+\.zip\z}
      )
      expect(request.body).to eq(uploaded_zip)
    end
  end

  it 'closes the debounce window when endpoint delivery fails' do
    allow(endpoint_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
    allow(endpoint_response).to receive(:code).and_return('500')
    allow(MR.logger).to receive(:error)
    allow(Airbrake).to receive(:notify)

    expect { service.call }.not_to raise_error

    expect(MR.logger).to have_received(:error).with(
      match(/Registry changeset endpoint delivery failed.*HTTP 500/)
    )
    expect(Airbrake).to have_received(:notify).with(
      an_instance_of(RuntimeError)
    )
    expect(sync.reload.last_synced_version_id).to eq(cutoff_version_id)
    expect(sync.last_synced_resource_event_id).to eq(cutoff_resource_event_id)
  end

  it 'places upserts and deletes in the required ZIP folders' do
    service.call

    entries = zip_entries(uploaded_objects.values.first.fetch(:body))

    expect(entries.keys).to include(
      "upserts/graphs/#{@upload_envelope.envelope_ceterms_ctid.downcase}.json",
      "upserts/resources/#{@upload_resource.resource_id.downcase}.json",
      "upserts/metadata/#{@upload_envelope.envelope_ceterms_ctid.downcase}.json",
      "deletes/graphs/#{@delete_envelope.envelope_ceterms_ctid.downcase}.json",
      "deletes/resources/#{@delete_resource_id.downcase}.json",
      "deletes/metadata/#{@delete_envelope.envelope_ceterms_ctid.downcase}.json"
    )

    delete_payload = JSON.parse(
      entries.fetch("deletes/resources/#{@delete_resource_id.downcase}.json")
    )
    expect(delete_payload).to include('identifier' => @delete_resource_id)
  end

  it 'marks both version and resource cutoffs synced after upload' do
    service.call

    expect(sync.reload.last_synced_version_id).to eq(cutoff_version_id)
    expect(sync.last_synced_resource_event_id).to eq(cutoff_resource_event_id)
  end

  def zip_entries(body)
    Zip::File.open_buffer(body).each_with_object({}) do |entry, entries|
      entries[entry.name] = entry.get_input_stream.read
    end
  end
end
