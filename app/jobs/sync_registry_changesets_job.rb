require 'registry_changeset_sync'
require 'sync_pending_registry_changesets'

class SyncRegistryChangesetsJob < ActiveJob::Base # rubocop:todo Style/Documentation
  def perform(sync_id)
    sync = RegistryChangesetSync.find(sync_id)
    last_activity_at = nil
    last_activity_version_id = nil
    last_activity_resource_event_id = nil
    pending_sync = false
    wait_until = nil

    sync.with_lock do
      last_activity_at = sync.last_activity_at
      last_activity_version_id = sync.last_activity_version_id
      last_activity_resource_event_id = sync.last_activity_resource_event_id
      pending_graph_sync = last_activity_version_id.present? &&
                           (sync.last_synced_version_id.blank? ||
                            sync.last_synced_version_id < last_activity_version_id)
      pending_resource_sync = last_activity_resource_event_id.present? &&
                              (sync.last_synced_resource_event_id.blank? ||
                               sync.last_synced_resource_event_id < last_activity_resource_event_id)
      pending_sync = pending_graph_sync || pending_resource_sync

      return if sync.scheduled_for_at.blank? && !pending_sync

      if sync.scheduled_for_at.present?
        wait_until = last_activity_at + RegistryChangesetSync.debounce_window

        if wait_until > Time.current
          sync.update!(scheduled_for_at: wait_until)
        else
          wait_until = nil
          sync.update!(scheduled_for_at: nil)
        end
      end
    end

    if wait_until
      self.class.set(wait_until: wait_until).perform_later(sync.id)
      return
    end

    return unless last_activity_at && pending_sync && sync.mark_syncing!

    begin
      SyncPendingRegistryChangesets.new(
        envelope_community: sync.envelope_community,
        cutoff_version_id: last_activity_version_id,
        cutoff_resource_event_id: last_activity_resource_event_id,
        sync: sync
      ).call
    rescue StandardError => e
      sync.mark_sync_error!(e)
      raise
    ensure
      sync.clear_syncing! if sync.reload.argo_workflows.blank?
    end
  end
end
