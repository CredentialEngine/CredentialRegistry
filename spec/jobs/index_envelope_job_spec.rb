require 'index_envelope_job'
require 'precalculate_description_sets'

RSpec.describe IndexEnvelopeJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }
    let(:resource) { envelope.envelope_resources.last }

    context 'no envelope' do
      before do
        expect(IndexEnvelopeResource).not_to receive(:call)
        expect(PrecalculateDescriptionSets).not_to receive(:process)
      end

      it 'does nothing' do
        IndexEnvelopeJob.new.perform(0)
      end
    end

    context 'with envelope' do
      before do
        expect(IndexEnvelopeResource).to receive(:call).with(resource)
        expect(PrecalculateDescriptionSets).to receive(:process).with(envelope)
      end

      it 'indexes resources and pre-calculates description sets' do
        IndexEnvelopeJob.new.perform(envelope.id)
      end
    end
  end
end
