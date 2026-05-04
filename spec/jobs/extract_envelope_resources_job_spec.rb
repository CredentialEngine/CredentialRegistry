require 'extract_envelope_resources_job'
require 'registry_changeset_sync'
require 'index_envelope_job'

RSpec.describe ExtractEnvelopeResourcesJob do
  it 'enqueues after open transactions commit' do
    expect(described_class.enqueue_after_transaction_commit).to be(true)
    expect(ActiveJob::Base.ancestors).to include(ActiveJob::EnqueueAfterTransactionCommit)
  end

  it 'defers enqueueing until the current transaction commits' do
    ActiveRecord::Base.transaction do
      described_class.perform_later(123)

      expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to be_empty
    end

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(1)
  end

  describe '#perform' do
    let(:version_id) { 123 }
    let(:resource_event_id) { 456 }

    before do
      allow(EnvelopeVersion).to receive_message_chain(:where, :maximum).and_return(version_id)
      allow(EnvelopeResourceSyncEvent).to receive_message_chain(:where, :maximum).and_return(resource_event_id)
    end

    context 'when the envelope has a CTID' do
      let(:envelope) { create(:envelope, :from_cer) }

      it 'records version and resource sync activity' do
        expect(ExtractEnvelopeResources).to receive(:call).with(envelope:)
        expect(IndexEnvelopeJob).to receive(:perform_later).with(envelope.id)
        expect(RegistryChangesetSync).to receive(:record_activity!).with(
          envelope.envelope_community,
          version_id: version_id,
          resource_event_id: resource_event_id
        )

        described_class.new.perform(envelope.id)
      end
    end

    context 'when the envelope does not have a CTID' do
      let(:envelope) do
        create(
          :envelope,
          envelope_community: create(:envelope_community, name: 'learning_registry'),
          envelope_ceterms_ctid: nil
        )
      end

      it 'still records resource sync activity without version sync activity' do
        expect(ExtractEnvelopeResources).to receive(:call).with(envelope:)
        expect(IndexEnvelopeJob).to receive(:perform_later).with(envelope.id)
        expect(RegistryChangesetSync).to receive(:record_activity!).with(
          envelope.envelope_community,
          version_id: nil,
          resource_event_id: resource_event_id
        )

        described_class.new.perform(envelope.id)
      end
    end
  end
end
