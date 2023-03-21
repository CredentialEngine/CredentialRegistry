require 'index_envelope_job'
require 'precalculate_description_sets_job'

RSpec.describe IndexEnvelopeJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }
    let(:resource) { envelope.envelope_resources.last }

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
        expect(IndexEnvelopeResource).to receive(:call).with(resource)
        expect(PrecalculateDescriptionSetsJob).to receive(:perform_later).with(envelope.id)
      end

      it 'indexes resources and pre-calculates description sets' do
        IndexEnvelopeJob.new.perform(envelope.id)
      end
    end
  end
end
