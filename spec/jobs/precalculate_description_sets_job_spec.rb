require 'precalculate_description_sets_job'

RSpec.describe PrecalculateDescriptionSetsJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }

    context 'no envelope' do # rubocop:todo RSpec/ContextWording
      before do
        # rubocop:todo RSpec/MessageSpies
        # rubocop:todo RSpec/ExpectInHook
        expect(PrecalculateDescriptionSets).not_to receive(:process)
        # rubocop:enable RSpec/ExpectInHook
        # rubocop:enable RSpec/MessageSpies
      end

      it 'does nothing' do
        described_class.new.perform(0)
      end
    end

    context 'with envelope' do
      before do
        # rubocop:todo RSpec/MessageSpies
        # rubocop:todo RSpec/ExpectInHook
        expect(PrecalculateDescriptionSets).to receive(:process).with(envelope)
        # rubocop:enable RSpec/ExpectInHook
        # rubocop:enable RSpec/MessageSpies
      end

      it 'pre-calculates description sets' do
        described_class.new.perform(envelope.id)
      end
    end
  end
end
