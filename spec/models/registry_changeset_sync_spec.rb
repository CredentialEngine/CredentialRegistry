require 'registry_changeset_sync'
require 'envelope_resource_sync_event'

RSpec.describe RegistryChangesetSync, type: :model do
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
  let(:resource_event) do
    EnvelopeResourceSyncEvent.create!(
      envelope_community: envelope_community,
      resource_id: 'ce-123-resource',
      action: EnvelopeResourceSyncEvent::ACTIONS[:upsert]
    )
  end

  describe '.record_activity!' do
    it 'schedules only one debounced job while the current one is still pending' do
      freeze_time do
        described_class.record_activity!(envelope_community, version_id: version.id)
        first_scheduled_for = described_class.find_by!(envelope_community:).scheduled_for_at
        travel 30.seconds
        expected_activity_at = Time.current

        expect do
          described_class.record_activity!(envelope_community, version_id: version.id)
        end.not_to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }

        sync = described_class.find_by!(envelope_community:)
        expect(sync.scheduled_for_at.to_i).to eq(first_scheduled_for.to_i)
        expect(sync.last_activity_at.to_i).to eq(expected_activity_at.to_i)
        expect(sync.last_activity_version_id).to eq(version.id)
      end
    end

    it 'tracks resource event activity on the same sync record' do
      described_class.record_activity!(
        envelope_community,
        version_id: version.id,
        resource_event_id: resource_event.id
      )

      sync = described_class.find_by!(envelope_community:)
      expect(sync.last_activity_version_id).to eq(version.id)
      expect(sync.last_activity_resource_event_id).to eq(resource_event.id)
    end
  end

  describe '.syncing?' do
    it 'returns true for an active sync lock' do
      described_class.create!(
        envelope_community:,
        last_activity_at: Time.current,
        syncing: true,
        syncing_started_at: Time.current
      )

      expect(described_class.syncing?(envelope_community)).to be(true)
    end

    it 'reconciles tracked Argo workflows before reporting the lock state' do
      sync = described_class.create!(
        envelope_community:,
        last_activity_at: Time.current,
        syncing: true,
        syncing_started_at: Time.current,
        argo_workflows: [{ 'name' => 'ce-registry-apply-changeset-graphs-abc123' }]
      )
      allow(SyncRegistryChangesetWorkflowStatus).to receive(:call) do |sync:|
        sync.clear_argo_workflows!
        sync.clear_syncing!
      end

      expect(described_class.syncing?(envelope_community)).to be(false)
      expect(SyncRegistryChangesetWorkflowStatus).to have_received(:call).with(sync:)
    end

    it 'returns false for a stale sync lock' do
      described_class.create!(
        envelope_community:,
        last_activity_at: Time.current,
        syncing: true,
        syncing_started_at: 16.minutes.ago
      )

      expect(described_class.syncing?(envelope_community)).to be(false)
      sync = described_class.find_by!(envelope_community:)
      expect(sync.syncing).to be(false)
      expect(sync.last_sync_error).to eq('Stale sync lock cleared after timeout')
      expect(sync.last_sync_finished_at).not_to be_nil
    end
  end

  describe '#mark_synced_through!' do
    let(:newer_version) do
      EnvelopeVersion.create!(
        item_type: 'Envelope',
        item_id: 2,
        event: 'create',
        envelope_community_id: envelope_community.id,
        envelope_ceterms_ctid: 'ce-456',
        created_at: Time.current
      )
    end

    it 'does not move the synced version backward' do
      older_version_id = version.id
      sync = described_class.create!(
        envelope_community: envelope_community,
        last_activity_at: Time.current,
        last_synced_version_id: newer_version.id
      )

      sync.mark_synced_through!(version_id: older_version_id)

      expect(sync.reload.last_synced_version_id).to eq(newer_version.id)
    end

    it 'does not move the synced resource event backward' do
      older_event = EnvelopeResourceSyncEvent.create!(
        envelope_community: envelope_community,
        resource_id: 'ce-111-resource',
        action: EnvelopeResourceSyncEvent::ACTIONS[:upsert]
      )
      newer_event = EnvelopeResourceSyncEvent.create!(
        envelope_community: envelope_community,
        resource_id: 'ce-999-resource',
        action: EnvelopeResourceSyncEvent::ACTIONS[:upsert]
      )
      sync = described_class.create!(
        envelope_community: envelope_community,
        last_activity_at: Time.current,
        last_synced_resource_event_id: newer_event.id
      )

      sync.mark_synced_through!(resource_event_id: older_event.id)

      expect(sync.reload.last_synced_resource_event_id).to eq(newer_event.id)
    end
  end
end
