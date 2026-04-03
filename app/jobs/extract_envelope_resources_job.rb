require 'extract_envelope_resources'
require 'registry_changeset_sync'
require 'index_envelope_job'
require 'precalculate_description_sets_job'

# Runs the ExtractEnvelopeResources service in background
class ExtractEnvelopeResourcesJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true

  def perform(envelope_id)
    envelope = Envelope.find(envelope_id)
    ExtractEnvelopeResources.call(envelope:)
    record_s3_sync_activity(envelope)
    IndexEnvelopeJob.perform_later(envelope_id)
  end

  private

  def record_s3_sync_activity(envelope)
    RegistryChangesetSync.record_activity!(
      envelope.envelope_community,
      version_id: version_id_for_s3_sync(envelope),
      resource_event_id: latest_resource_event_id(envelope)
    )
  end

  def version_id_for_s3_sync(envelope)
    return if envelope.envelope_ceterms_ctid.blank?

    EnvelopeVersion.where(item_type: 'Envelope', item_id: envelope.id).maximum(:id)
  end

  def latest_resource_event_id(envelope)
    EnvelopeResourceSyncEvent.where(
      envelope_community: envelope.envelope_community
    ).maximum(:id)
  end
end
