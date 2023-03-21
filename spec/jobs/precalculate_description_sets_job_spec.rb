require 'precalculate_description_sets_job'

RSpec.describe PrecalculateDescriptionSetsJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }

    context 'no envelope' do
      before do
        expect(PrecalculateDescriptionSets).not_to receive(:process)
      end

      it 'does nothing' do
        PrecalculateDescriptionSetsJob.new.perform(0)
      end
    end

    context 'with envelope' do
      before do
        expect(PrecalculateDescriptionSets).to receive(:process).with(envelope)
      end

      it 'pre-calculates description sets' do
        PrecalculateDescriptionSetsJob.new.perform(envelope.id)
      end
    end
  end
end
