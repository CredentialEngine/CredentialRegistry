require 'envelope_metadata'
require 'json'
require 'net/http'
require 'set'
require 'stringio'
require 'uri'
require 'uuid'
require 'zip'
require 'envelope_resource_sync_event'
require 'envelope_resource'

# Builds one debounced registry changeset ZIP and uploads only that ZIP to S3.
class SyncPendingRegistryChangesets
  ENTITY_TYPES = %i[graphs resources metadata].freeze

  attr_reader :cutoff_resource_event_id, :cutoff_version_id, :envelope_community, :sync

  def initialize(envelope_community:, cutoff_version_id:, cutoff_resource_event_id: nil, sync: nil)
    @envelope_community = envelope_community
    @cutoff_version_id = cutoff_version_id
    @cutoff_resource_event_id = cutoff_resource_event_id
    @sync = sync
  end

  def call
    actions = {
      graphs: latest_versions.filter_map { |version| sync_version(version) },
      resources: latest_resource_events.filter_map { |event| sync_resource_event(event) },
      metadata: latest_versions.filter_map { |version| sync_metadata_version(version) }
    }

    deliver_changeset(actions) if actions.values.any?(&:any?)
    mark_synced!
  end

  private

  def latest_versions
    return EnvelopeVersion.none unless cutoff_version_id

    scope = EnvelopeVersion
            .where(item_type: 'Envelope', envelope_community_id: envelope_community.id)
            .where.not(envelope_ceterms_ctid: nil)
            .where('id <= ?', cutoff_version_id)

    version_id = sync&.last_synced_version_id
    scope = scope.where('id > ?', version_id) if version_id

    latest_version_ids = scope.select('MAX(versions.id)').group(:envelope_ceterms_ctid)
    EnvelopeVersion.where(id: latest_version_ids).order(:id)
  end

  def latest_resource_events
    return EnvelopeResourceSyncEvent.none unless cutoff_resource_event_id

    scope = EnvelopeResourceSyncEvent
            .where(envelope_community: envelope_community)
            .where('id <= ?', cutoff_resource_event_id)

    event_id = sync&.last_synced_resource_event_id
    scope = scope.where('id > ?', event_id) if event_id

    latest_event_ids = scope
                       .select('MAX(envelope_resource_sync_events.id)')
                       .group(:resource_id)
    EnvelopeResourceSyncEvent.where(id: latest_event_ids).order(:id)
  end

  def sync_version(version)
    version.event == 'destroy' ? delete_version(version) : upload_version(version)
  end

  def sync_metadata_version(version)
    version.event == 'destroy' ? delete_metadata_version(version) : upload_metadata_version(version)
  end

  def sync_resource_event(event)
    return unless resource_sync_ctid?(event.resource_id)

    event.delete? ? delete_resource_event(event) : upload_resource_event(event)
  end

  def upload_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    envelope = Envelope.unscoped.find_by(id: version.item_id)
    return delete_version(version) unless envelope

    action_payload(version.envelope_ceterms_ctid, version.created_at, envelope.processed_resource)
  end

  def delete_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    envelope = version.reify
    return delete_payload(version.envelope_ceterms_ctid, version.created_at) unless envelope

    delete_payload(version.envelope_ceterms_ctid, version.created_at, envelope.processed_resource)
  end

  def upload_metadata_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    envelope = Envelope.unscoped.find_by(id: version.item_id)
    return delete_metadata_version(version) unless envelope

    action_payload(
      version.envelope_ceterms_ctid,
      version.created_at,
      EnvelopeMetadata.from_envelope(envelope).as_json
    )
  end

  def delete_metadata_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    envelope = version.reify
    return delete_payload(version.envelope_ceterms_ctid, version.created_at) unless envelope

    delete_payload(
      version.envelope_ceterms_ctid,
      version.created_at,
      EnvelopeMetadata.from_envelope(envelope).as_json
    )
  end

  def upload_resource_event(event)
    return if superseded_after_cutoff_resource_ids.include?(event.resource_id)

    resource = EnvelopeResource
               .not_deleted
               .in_community(envelope_community.name)
               .includes(:envelope)
               .find_by(resource_id: event.resource_id)
    return delete_resource_event(event) unless resource

    payload = resource.processed_resource.merge(
      '@context' => resource.envelope.processed_resource['@context']
    )
    action_payload(event.resource_id, event.created_at, payload)
  end

  def delete_resource_event(event)
    return if superseded_after_cutoff_resource_ids.include?(event.resource_id)

    delete_payload(event.resource_id, event.created_at, event.payload)
  end

  def action_payload(identifier, updated_at, payload)
    { action: :upsert, identifier: identifier, payload: payload, updated_at: updated_at.iso8601 }
  end

  def delete_payload(identifier, updated_at, payload = nil)
    { action: :delete, identifier: identifier, payload: payload, updated_at: updated_at.iso8601 }
  end

  def deliver_changeset(actions)
    raise 'Registry changeset S3 bucket is not configured' if s3_bucket_name.blank?

    key = changeset_key
    body = changeset_zip(actions)

    s3_bucket.object(key).put(
      body: body,
      content_type: 'application/zip'
    )

    deliver_changeset_to_endpoint(body, key) if changeset_endpoint.present?
  end


  def deliver_changeset_to_endpoint(body, key)
    post_changeset_zip(body, key)
  rescue StandardError => e
    MR.logger.error(
      "Registry changeset endpoint delivery failed for #{key}: #{e.class}: #{e.message}"
    )
    Airbrake.notify(e) if defined?(Airbrake)
  end

  def post_changeset_zip(body, key)
    uri = URI.parse(changeset_endpoint)
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/zip'
    request['Content-Disposition'] = %(attachment; filename="#{File.basename(key)}")
    request['X-Registry-Community'] = envelope_community.name
    request['X-Registry-Changeset-Key'] = key
    request.body = body

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: uri.scheme == 'https',
      open_timeout: changeset_endpoint_timeout,
      read_timeout: changeset_endpoint_timeout
    ) { |http| http.request(request) }

    return if response.is_a?(Net::HTTPSuccess)

    raise "Registry changeset endpoint returned HTTP #{response.code}"
  end

  def changeset_endpoint
    ENV['REGISTRY_CHANGESET_SYNC_ENDPOINT'].presence
  end

  def changeset_endpoint_timeout
    ENV.fetch('REGISTRY_CHANGESET_SYNC_ENDPOINT_TIMEOUT_SECONDS', 30).to_i
  end

  def changeset_zip(actions)
    Zip::OutputStream.write_buffer do |zip|
      ENTITY_TYPES.each do |entity_type|
        actions.fetch(entity_type).each do |action|
          zip.put_next_entry(zip_entry(entity_type, action))
          zip.write(JSON.generate(zip_payload(action)))
        end
      end
    end.string
  end

  def zip_entry(entity_type, action)
    root = action.fetch(:action) == :upsert ? "upserts/#{entity_type}" : "deletes/#{entity_type}"
    "#{root}/#{safe_filename(action.fetch(:identifier))}.json"
  end

  def zip_payload(action)
    payload = action[:payload]
    return payload if payload.present?

    {
      identifier: action.fetch(:identifier),
      deleted_at: action.fetch(:updated_at)
    }
  end

  def safe_filename(identifier)
    identifier.to_s.downcase.gsub(%r{[^a-z0-9._-]+}, '_')
  end

  def changeset_key
    "#{envelope_community.name}/changesets/#{timestamp}.zip"
  end

  def timestamp
    @timestamp ||= Time.current.utc.iso8601(6).tr(':', '-')
  end

  def mark_synced!
    sync&.mark_synced_through!(
      version_id: cutoff_version_id,
      resource_event_id: cutoff_resource_event_id
    )
  end

  def superseded_after_cutoff_ctids
    return Set.new unless cutoff_version_id

    @superseded_after_cutoff_ctids ||= EnvelopeVersion
                                      .where(
                                        item_type: 'Envelope',
                                        envelope_community_id: envelope_community.id
                                      )
                                      .where.not(envelope_ceterms_ctid: nil)
                                      .where('id > ?', cutoff_version_id)
                                      .distinct
                                      .pluck(:envelope_ceterms_ctid)
                                      .to_set
  end

  def superseded_after_cutoff_resource_ids
    return Set.new unless cutoff_resource_event_id

    @superseded_after_cutoff_resource_ids ||= EnvelopeResourceSyncEvent
                                              .where(envelope_community: envelope_community)
                                              .where('id > ?', cutoff_resource_event_id)
                                              .distinct
                                              .pluck(:resource_id)
                                              .to_set
  end

  def resource_sync_ctid?(value)
    return false unless value&.start_with?('ce-')

    UUID.validate(value[3..])
  end

  def s3_bucket
    @s3_bucket ||= s3_resource.bucket(s3_bucket_name)
  end

  def s3_bucket_name
    (
      ENV['REGISTRY_CHANGESET_SYNC_BUCKET'] ||
      ENV['REGISTRY_CHANGESET_SYNC_SOURCE_BUCKET'] ||
      ENV['ENVELOPE_GRAPHS_BUCKET']
    ).presence
  end

  def s3_resource
    @s3_resource ||= Aws::S3::Resource.new(**s3_resource_options)
  end

  def s3_resource_options
    options = { region: ENV.fetch('AWS_REGION') }
    endpoint = ENV['AWS_ENDPOINT_URL_S3'].presence
    return options unless endpoint

    options.merge(
      endpoint: endpoint,
      force_path_style: ENV.fetch('AWS_S3_FORCE_PATH_STYLE', 'false').casecmp?('true')
    )
  end
end
