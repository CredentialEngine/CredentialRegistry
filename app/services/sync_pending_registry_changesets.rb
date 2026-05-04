require 'digest'
require 'envelope_metadata'
require 'rubygems/package'
require 'json'
require 'set'
require 'stringio'
require 'zlib'
require 'uuid'
require 'envelope_resource_sync_event'
require 'envelope_resource'
require 'submit_changeset_workflow'

# Syncs pending registry changesets to S3 and submits apply-changeset workflows.
class SyncPendingRegistryChangesets
  attr_reader :cutoff_resource_event_id, :cutoff_version_id, :envelope_community, :sync

  def initialize(envelope_community:, cutoff_version_id:, cutoff_resource_event_id: nil, sync: nil)
    @envelope_community = envelope_community
    @cutoff_version_id = cutoff_version_id
    @cutoff_resource_event_id = cutoff_resource_event_id
    @sync = sync
  end

  def call
    return mark_synced! unless s3_bucket_name

    graph_actions = latest_versions.filter_map { |version| sync_version(version) }
    metadata_actions = latest_versions.filter_map { |version| sync_metadata_version(version) }
    resource_actions = latest_resource_events.filter_map { |event| sync_resource_event(event) }

    workflows = [
      upload_changeset(:graphs, graph_actions),
      upload_changeset(:metadata, metadata_actions),
      upload_changeset(:resources, resource_actions)
    ].compact.map { |changeset| submit_changeset_workflow(changeset) }
    sync&.record_argo_workflows!(workflows)
    mark_synced! if workflows.empty?
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

    latest_version_ids = scope
                         .select('MAX(versions.id)')
                         .group(:envelope_ceterms_ctid)

    EnvelopeVersion
      .where(id: latest_version_ids)
      .order(:id)
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

    EnvelopeResourceSyncEvent
      .where(id: latest_event_ids)
      .order(:id)
  end

  def sync_version(version)
    if version.event == 'destroy'
      delete_version(version)
    else
      upload_version(version)
    end
  end

  def sync_metadata_version(version)
    if version.event == 'destroy'
      delete_metadata_version(version)
    else
      upload_metadata_version(version)
    end
  end

  def sync_resource_event(event)
    return unless resource_sync_ctid?(event.resource_id)

    if event.delete?
      delete_resource_event(event)
    else
      upload_resource_event(event)
    end
  end

  def upload_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    envelope = Envelope.unscoped.find_by(id: version.item_id)
    return delete_version(version) unless envelope

    action_payload(version, action: 'upload', payload: envelope.processed_resource)
  end

  def delete_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    action_payload(version, action: 'delete')
  end

  def upload_metadata_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    envelope = Envelope.unscoped.find_by(id: version.item_id)
    return delete_metadata_version(version) unless envelope

    metadata_action_payload(version, action: 'upload', payload: metadata_payload(envelope))
  end

  def delete_metadata_version(version)
    return if superseded_after_cutoff_ctids.include?(version.envelope_ceterms_ctid)

    metadata_action_payload(version, action: 'delete')
  end

  def upload_resource_event(event)
    return if superseded_after_cutoff_resource_ids.include?(event.resource_id)

    resource = EnvelopeResource
               .not_deleted
               .in_community(envelope_community.name)
               .includes(:envelope)
               .find_by(resource_id: event.resource_id)
    return delete_resource_event(event) unless resource

    resource_action_payload(event, action: 'upload', payload: resource_payload(resource))
  end

  def delete_resource_event(event)
    return if superseded_after_cutoff_resource_ids.include?(event.resource_id)

    resource_action_payload(event, action: 'delete')
  end

  def superseded_after_cutoff_ctids
    @superseded_after_cutoff_ctids ||= EnvelopeVersion
                                      .where(item_type: 'Envelope',
                                             envelope_community_id: envelope_community.id)
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

  def action_payload(version, action:, payload: nil)
    {
      envelope_ceterms_ctid: version.envelope_ceterms_ctid,
      action: action,
      s3_key: graph_s3_key(version),
      payload: payload,
      updated_at: version.created_at.iso8601
    }.compact
  end

  def mark_synced!
    sync&.mark_synced_through!(
      version_id: cutoff_version_id,
      resource_event_id: cutoff_resource_event_id
    )
  end

  def upload_changeset(entity_type, actions)
    changeset_key = changeset_key(entity_type)
    manifest_payload = manifest_body(entity_type, actions, changeset_key)
    return unless manifest_payload

    manifest_key = changeset_manifest_key(entity_type)

    upload_changeset_archive(changeset_key, actions)
    upload_gzip_json(manifest_key, manifest_payload)
    { entity_type: entity_type, manifest_key: manifest_key }
  end

  def submit_changeset_workflow(changeset)
    return if changeset[:manifest_key].blank?

    workflow = SubmitChangesetWorkflow.call(
      envelope_community: envelope_community,
      entity_type: changeset.fetch(:entity_type),
      manifest_key: changeset.fetch(:manifest_key)
    )
    workflow_name = workflow.dig(:metadata, :name)

    {
      'entity_type' => changeset.fetch(:entity_type).to_s,
      'manifest_key' => changeset.fetch(:manifest_key),
      'name' => workflow_name,
      'namespace' => workflow[:namespace]
    }.compact
  end

  def gzip_json(payload)
    io = StringIO.new

    Zlib::GzipWriter.wrap(io) do |gzip|
      gzip.write(JSON.generate(payload))
    end

    io.string
  end

  def upload_gzip_json(key, payload)
    s3_bucket.object(key).put(
      body: gzip_json(payload),
      content_encoding: 'gzip',
      content_type: 'application/json'
    )
  end

  def upload_changeset_archive(key, actions)
    s3_bucket.object(key).put(
      body: tar_gzip(actions),
      content_encoding: 'gzip',
      content_type: 'application/x-tar'
    )
  end

  def tar_gzip(actions)
    io = StringIO.new

    Zlib::GzipWriter.wrap(io) do |gzip|
      Gem::Package::TarWriter.new(gzip) do |tar|
        actions.each do |action|
          next unless action[:action] == 'upload'

          document = JSON.generate(action.fetch(:payload))
          tar.add_file_simple(action.fetch(:s3_key), 0o644, document.bytesize) do |file|
            file.write(document)
          end
        end
      end
    end

    io.string
  end

  def manifest_body(entity_type, actions, changeset_key)
    manifest_upserts = actions.filter_map do |action|
      manifest_item_payload(action) if action[:action] == 'upload'
    end
    manifest_deletes = actions.filter_map do |action|
      manifest_item_payload(action) if action[:action] == 'delete'
    end
    return if manifest_upserts.empty? && manifest_deletes.empty?

    {
      bucket: s3_bucket_name,
      entity_type: entity_type.to_s,
      changeset_key: changeset_key,
      upserts: manifest_upserts,
      deletes: manifest_deletes
    }
  end

  def manifest_item_payload(action)
    action.slice(:envelope_ceterms_ctid, :resource_id, :updated_at).merge(key: action[:s3_key])
  end

  def changeset_key(entity_type)
    "#{envelope_community.name}/changesets/#{entity_type}/#{timestamp}.tar.gz"
  end

  def changeset_manifest_key(entity_type)
    "#{envelope_community.name}/changesets/manifests/#{entity_type}-#{timestamp}.gz"
  end

  def timestamp
    @timestamp ||= Time.current.utc.iso8601(6).tr(':', '-')
  end

  def graph_s3_key(version)
    "#{envelope_community.name}/graphs/#{version.envelope_ceterms_ctid}.json"
  end

  def resource_s3_key(resource_id)
    "#{envelope_community.name}/resources/#{resource_id.downcase}.json"
  end

  def metadata_s3_key(version)
    "#{envelope_community.name}/metadata/#{version.envelope_ceterms_ctid}.json"
  end

  def metadata_payload(envelope)
    EnvelopeMetadata.from_envelope(envelope).as_json
  end

  def resource_payload(resource)
    resource.processed_resource.merge('@context' => resource.envelope.processed_resource['@context'])
  end

  def metadata_action_payload(version, action:, payload: nil)
    {
      envelope_ceterms_ctid: version.envelope_ceterms_ctid,
      action: action,
      s3_key: metadata_s3_key(version),
      payload: payload,
      updated_at: version.created_at.iso8601
    }.compact
  end

  def resource_action_payload(event, action:, payload: nil)
    {
      resource_id: event.resource_id,
      action: action,
      s3_key: resource_s3_key(event.resource_id),
      payload: payload,
      updated_at: event.created_at.iso8601
    }.compact
  end

  def resource_sync_ctid?(value)
    return false unless value&.start_with?('ce-')

    UUID.validate(value[3..])
  end

  def s3_bucket
    @s3_bucket ||= s3_resource.bucket(s3_bucket_name)
  end

  def s3_bucket_name
    (ENV['REGISTRY_CHANGESET_SYNC_SOURCE_BUCKET'] || ENV['ENVELOPE_GRAPHS_BUCKET']).presence
  end

  def s3_resource
    @s3_resource ||= Aws::S3::Resource.new(region: ENV['AWS_REGION'].presence)
  end
end
