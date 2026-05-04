require 'sync_registry_changesets_job'

RSpec.describe SyncRegistryChangesetsJob do
  subject(:job) { described_class }

  let(:envelope_community) { create(:envelope_community, name: 'ce_registry') }
  let(:sync) do
    RegistryChangesetSync.create!(
      envelope_community:,
      last_activity_at: last_activity_at,
      scheduled_for_at: scheduled_for_at,
      last_activity_version_id: version.id
    )
  end
  let(:scheduled_for_at) { Time.current }
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

  describe '#perform' do
    context 'when the quiet period has not elapsed' do
      let(:last_activity_at) { 30.seconds.ago }

      it 'reschedules the sync job for the end of the debounce window' do
        allow(SyncPendingRegistryChangesets).to receive(:new)

        expect do
          described_class.new.perform(sync.id)
        end.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)

        queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
        expect(queued_job.fetch('job_class')).to eq(described_class.to_s)
        expect(queued_job.fetch('arguments')).to eq([sync.id])

        expect(sync.reload.scheduled_for_at.to_i).to eq((last_activity_at + 60.seconds).to_i)
        expect(SyncPendingRegistryChangesets).not_to have_received(:new)
      end
    end

    context 'when the quiet period has elapsed' do
      let(:last_activity_at) { 61.seconds.ago }
      let(:service) do
        instance_double(SyncPendingRegistryChangesets).tap do |service|
          allow(service).to receive(:call) do
            sync.record_argo_workflows!([{ 'name' => 'ce-registry-apply-changeset-graphs-abc123' }])
          end
        end
      end

      it 'flushes the pending S3 sync batch and keeps the lock until Argo finishes' do
        allow(SyncPendingRegistryChangesets).to receive(:new).and_return(service)

        job.perform_now(sync.id)

        expect(SyncPendingRegistryChangesets).to have_received(:new).with(
          envelope_community:,
          cutoff_version_id: version.id,
          cutoff_resource_event_id: nil,
          sync:
        )
        expect(service).to have_received(:call)
        expect(sync.reload.scheduled_for_at).to be_nil
        expect(sync.reload.syncing).to be(true)
        expect(sync.reload.syncing_started_at).not_to be_nil
        expect(sync.reload.argo_workflows).to eq([{ 'name' => 'ce-registry-apply-changeset-graphs-abc123' }])
      end
    end

    context 'when the batch sync raises' do
      let(:last_activity_at) { 61.seconds.ago }
      let(:service) { instance_double(SyncPendingRegistryChangesets) }

      it 'records the error and clears the lock' do
        allow(SyncPendingRegistryChangesets).to receive(:new).and_return(service)
        allow(service).to receive(:call).and_raise(StandardError, 'boom')

        expect do
          job.perform_now(sync.id)
        end.to raise_error(StandardError, 'boom')

        sync.reload
        expect(sync.syncing).to be(false)
        expect(sync.syncing_started_at).to be_nil
        expect(sync.last_sync_error).to eq('StandardError: boom')
        expect(sync.last_sync_finished_at).not_to be_nil
      end
    end

    context 'when a retry runs after a failed flush cleared scheduled_for_at' do
      let(:last_activity_at) { 61.seconds.ago }
      let(:service) { instance_double(SyncPendingRegistryChangesets) }

      it 'still performs the pending sync' do
        allow(SyncPendingRegistryChangesets).to receive(:new).and_return(service)
        allow(service).to receive(:call).and_raise(StandardError, 'boom').once

        expect do
          job.perform_now(sync.id)
        end.to raise_error(StandardError, 'boom')

        sync.reload
        expect(sync.scheduled_for_at).to be_nil
        expect(sync.last_synced_version_id).to be_nil

        allow(service).to receive(:call).and_return(true)

        expect do
          job.perform_now(sync.id)
        end.not_to raise_error

        expect(SyncPendingRegistryChangesets).to have_received(:new).twice
        expect(service).to have_received(:call).twice
      end
    end

    context 'when only resource sync work is pending' do
      let(:last_activity_at) { 61.seconds.ago }
      let(:service) { instance_double(SyncPendingRegistryChangesets, call: true) }

      before do
        resource_event = EnvelopeResourceSyncEvent.create!(
          envelope_community: envelope_community,
          resource_id: 'https://example.org/resources/alpha',
          action: EnvelopeResourceSyncEvent::ACTIONS[:upsert]
        )
        sync.update!(
          last_activity_version_id: nil,
          last_activity_resource_event_id: resource_event.id,
          last_synced_resource_event_id: nil
        )
      end

      it 'flushes the pending resource batch' do
        allow(SyncPendingRegistryChangesets).to receive(:new).and_return(service)

        job.perform_now(sync.id)

        expect(SyncPendingRegistryChangesets).to have_received(:new).with(
          envelope_community:,
          cutoff_version_id: nil,
          cutoff_resource_event_id: sync.last_activity_resource_event_id,
          sync:
        )
        expect(service).to have_received(:call)
      end
    end
  end
end
