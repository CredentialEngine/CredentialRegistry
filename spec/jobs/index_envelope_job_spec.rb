require 'index_envelope_job'
require 'precalculate_description_sets_job'

RSpec.describe IndexEnvelopeJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }
    let(:resource) { envelope.envelope_resources.last }

    before do
      allow(Parallel).to receive(:each).and_yield(resource.id)
    end

    context 'no envelope' do
      before do
        expect(IndexEnvelopeResource).not_to receive(:call)
        expect(PrecalculateDescriptionSetsJob).not_to receive(:perform_later)
      end

      it 'does nothing' do
        IndexEnvelopeJob.new.perform(0)
      end
    end

    context 'with envelope' do
      before do
        expect(PrecalculateDescriptionSetsJob).to receive(:perform_later)
          .with(envelope.id)
      end

      context 'duplicate' do
        let(:error) { ActiveRecord::RecordNotUnique.new }

        before do
          expect(Airbrake).to receive(:notify)
            .with(error, resource_id: resource.resource_id)

          expect(IndexEnvelopeResource).to receive(:call)
            .with(resource)
            .and_raise(error)
        end

        it 'logs error' do
          IndexEnvelopeJob.new.perform(envelope.id)
        end
      end

      context 'all good' do
        before do
          expect(Airbrake).not_to receive(:notify)
          expect(IndexEnvelopeResource).to receive(:call).with(resource)
        end

        it 'indexes resources and pre-calculates description sets' do
          IndexEnvelopeJob.new.perform(envelope.id)
        end
      end
    end
  end
end
