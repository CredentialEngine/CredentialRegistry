# Tracks debounced registry changeset sync scheduling for an envelope community.
require 'sync_registry_changesets_job'
require 'sync_registry_changeset_workflow_status'

class RegistryChangesetSync < ActiveRecord::Base
  PUBLISH_LOCKED = 'Publishing is temporarily locked while registry changeset sync is in progress'.freeze

  belongs_to :envelope_community

  validates :envelope_community_id, uniqueness: true
  validates :last_activity_at, presence: true

  class << self
    def debounce_window
      (
        ENV['REGISTRY_CHANGESET_SYNC_DEBOUNCE_SECONDS'].presence ||
        '60'
      ).to_i.seconds
    end

    def sync_lock_timeout
      (
        ENV['REGISTRY_CHANGESET_SYNC_LOCK_TIMEOUT_SECONDS'].presence ||
        '600'
      ).to_i.seconds
    end

    def syncing?(envelope_community)
      sync = find_by(envelope_community: envelope_community)
      return false unless sync

      SyncRegistryChangesetWorkflowStatus.call(sync: sync) if sync.syncing? && sync.argo_workflows.present?
      sync.syncing?
    end

    def record_activity!(envelope_community, version_id: nil, resource_event_id: nil)
      return unless version_id || resource_event_id

      sync = find_or_create_by!(envelope_community: envelope_community) do |record|
        record.last_activity_at = Time.current
        record.last_synced_version_id = previous_version_id(envelope_community, version_id) if version_id
        if resource_event_id
          record.last_synced_resource_event_id = previous_resource_event_id(
            envelope_community,
            resource_event_id
          )
        end
      end

      wait_until = nil

      sync.with_lock do
        now = Time.current
        sync.last_activity_at = now
        sync.last_activity_version_id = [
          sync.last_activity_version_id,
          version_id
        ].compact.max if version_id
        sync.last_activity_resource_event_id = [
          sync.last_activity_resource_event_id,
          resource_event_id
        ].compact.max if resource_event_id

        if sync.scheduled_for_at.blank? || sync.scheduled_for_at <= now
          wait_until = now + debounce_window
          sync.scheduled_for_at = wait_until
        end

        sync.save!
      end

      if wait_until
        SyncRegistryChangesetsJob.set(wait_until: wait_until).perform_later(sync.id)
      end

      sync
    end

    private

    def previous_version_id(envelope_community, version_id)
      EnvelopeVersion
        .where(item_type: 'Envelope', envelope_community_id: envelope_community.id)
        .where('id < ?', version_id)
        .maximum(:id)
    end

    def previous_resource_event_id(envelope_community, resource_event_id)
      EnvelopeResourceSyncEvent
        .where(envelope_community: envelope_community)
        .where('id < ?', resource_event_id)
        .maximum(:id)
    end
  end

  def syncing?
    return false unless syncing

    clear_stale_sync! if stale_sync?

    syncing
  end

  def mark_syncing!
    with_lock do
      clear_stale_sync! if stale_sync?
      return false if syncing

      update!(
        syncing: true,
        syncing_started_at: Time.current,
        argo_workflows: [],
        last_sync_error: nil
      )
    end

    true
  end

  def clear_syncing!
    update!(
      syncing: false,
      syncing_started_at: nil,
      last_sync_finished_at: Time.current
    )
  end

  def mark_sync_error!(error)
    update!(last_sync_error: "#{error.class}: #{error.message}")
  end

  def record_argo_workflows!(workflows)
    update!(argo_workflows: workflows)
  end

  def clear_argo_workflows!
    update!(argo_workflows: [])
  end

  def mark_synced_through!(version_id: nil, resource_event_id: nil)
    with_lock do
      attrs = {}
      attrs[:last_synced_version_id] = [
        last_synced_version_id,
        version_id
      ].compact.max if version_id
      attrs[:last_synced_resource_event_id] = [
        last_synced_resource_event_id,
        resource_event_id
      ].compact.max if resource_event_id

      update!(attrs) if attrs.any?
    end
  end

  def stale_sync?
    syncing && syncing_started_at.present? && syncing_started_at <= self.class.sync_lock_timeout.ago
  end

  def clear_stale_sync!
    return unless stale_sync?

    MR.log_with_labels(
      :warn,
      'Clearing stale registry changeset sync lock',
      envelope_community: envelope_community.name,
      syncing_started_at: syncing_started_at.iso8601,
      timeout_seconds: self.class.sync_lock_timeout.to_i
    )

    update!(
      syncing: false,
      syncing_started_at: nil,
      last_sync_finished_at: Time.current,
      last_sync_error: 'Stale sync lock cleared after timeout'
    )
  end
end
